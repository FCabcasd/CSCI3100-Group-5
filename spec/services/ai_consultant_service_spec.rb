require 'rails_helper'

RSpec.describe AiConsultantService do
  subject(:service) { described_class.new }

  describe '#available?' do
    it 'returns false when no API key is configured' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("GEMINI_API_KEY").and_return(nil)
      svc = described_class.new
      expect(svc.available?).to be false
    end
  end

  describe '#answer_question' do
    context 'when API key is not configured' do
      it 'returns unavailable response' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("GEMINI_API_KEY").and_return(nil)
        svc = described_class.new
        result = svc.answer_question(question: "What are the rules?")
        expect(result[:success]).to be false
        expect(result[:answer]).to include("not available")
      end
    end

    context 'when API key is configured' do
      let(:gemini_success_response) do
        instance_double(Net::HTTPOK, code: "200", body: {
          "candidates" => [ { "content" => { "parts" => [ { "text" => "You can book venues online." } ] } } ]
        }.to_json)
      end

      it 'calls Gemini and returns answer' do
        svc = described_class.new
        allow(svc).to receive(:available?).and_return(true)
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:use_ssl=)
        allow(http_double).to receive(:open_timeout=)
        allow(http_double).to receive(:read_timeout=)
        allow(http_double).to receive(:request).and_return(gemini_success_response)

        result = svc.answer_question(
          question: "How do I book?",
          user_context: { name: "Alice", points: 100, role: "user" }
        )
        expect(result[:success]).to be true
        expect(result[:answer]).to eq("You can book venues online.")
      end

      it 'handles API errors gracefully' do
        svc = described_class.new
        allow(svc).to receive(:available?).and_return(true)
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:use_ssl=)
        allow(http_double).to receive(:open_timeout=)
        allow(http_double).to receive(:read_timeout=)
        allow(http_double).to receive(:request).and_raise(StandardError.new("API error"))

        result = svc.answer_question(question: "test")
        expect(result[:success]).to be false
        expect(result[:answer]).to include("error")
      end
    end
  end

  describe '#recommend_venues' do
    it 'returns unavailable when no API key' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("GEMINI_API_KEY").and_return(nil)
      svc = described_class.new
      result = svc.recommend_venues(requirements: "50 people room")
      expect(result[:success]).to be false
    end

    context 'when API key is configured' do
      let(:tenant) { create(:tenant) }
      let(:gemini_success_response) do
        instance_double(Net::HTTPOK, code: "200", body: {
          "candidates" => [ { "content" => { "parts" => [ { "text" => "I recommend Venue A for your needs." } ] } } ]
        }.to_json)
      end

      before do
        create_list(:venue, 2, tenant: tenant, is_active: true)
      end

      it 'returns recommendations with venue count' do
        svc = described_class.new
        allow(svc).to receive(:available?).and_return(true)
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:use_ssl=)
        allow(http_double).to receive(:open_timeout=)
        allow(http_double).to receive(:read_timeout=)
        allow(http_double).to receive(:request).and_return(gemini_success_response)

        result = svc.recommend_venues(requirements: "50 people room", tenant_id: tenant.id)
        expect(result[:success]).to be true
        expect(result[:answer]).to include("recommend")
        expect(result[:venues_found]).to eq(2)
      end

      it 'handles API errors gracefully' do
        svc = described_class.new
        allow(svc).to receive(:available?).and_return(true)
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:use_ssl=)
        allow(http_double).to receive(:open_timeout=)
        allow(http_double).to receive(:read_timeout=)
        allow(http_double).to receive(:request).and_raise(StandardError.new("timeout"))

        result = svc.recommend_venues(requirements: "test")
        expect(result[:success]).to be false
        expect(result[:answer]).to include("error")
      end
    end
  end

  describe '#check_booking_conflicts' do
    let(:tenant) { create(:tenant) }
    let(:venue) { create(:venue, tenant: tenant) }

    it 'returns unavailable when no API key' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("GEMINI_API_KEY").and_return(nil)
      svc = described_class.new
      result = svc.check_booking_conflicts(
        venue_id: venue.id,
        start_time: 1.day.from_now.iso8601,
        end_time: (1.day.from_now + 2.hours).iso8601
      )
      expect(result[:success]).to be false
    end

    context 'when API key is configured' do
      let(:user) { create(:user, tenant: tenant) }
      let(:gemini_success_response) do
        instance_double(Net::HTTPOK, code: "200", body: {
          "candidates" => [ { "content" => { "parts" => [ { "text" => "The time slot is available." } ] } } ]
        }.to_json)
      end
      let(:gemini_conflict_response) do
        instance_double(Net::HTTPOK, code: "200", body: {
          "candidates" => [ { "content" => { "parts" => [ { "text" => "There is a conflict." } ] } } ]
        }.to_json)
      end

      it 'returns no conflicts for open slot' do
        svc = described_class.new
        allow(svc).to receive(:available?).and_return(true)
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:use_ssl=)
        allow(http_double).to receive(:open_timeout=)
        allow(http_double).to receive(:read_timeout=)
        allow(http_double).to receive(:request).and_return(gemini_success_response)

        result = svc.check_booking_conflicts(
          venue_id: venue.id,
          start_time: 2.days.from_now.iso8601,
          end_time: (2.days.from_now + 1.hour).iso8601
        )
        expect(result[:success]).to be true
        expect(result[:has_conflicts]).to be false
        expect(result[:conflict_count]).to eq(0)
      end

      it 'detects existing booking conflicts' do
        create(:booking, venue: venue, user: user, status: :confirmed,
               start_time: 3.days.from_now.change(hour: 10),
               end_time: 3.days.from_now.change(hour: 12))

        svc = described_class.new
        allow(svc).to receive(:available?).and_return(true)
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:use_ssl=)
        allow(http_double).to receive(:open_timeout=)
        allow(http_double).to receive(:read_timeout=)
        allow(http_double).to receive(:request).and_return(gemini_conflict_response)

        result = svc.check_booking_conflicts(
          venue_id: venue.id,
          start_time: 3.days.from_now.change(hour: 11).iso8601,
          end_time: 3.days.from_now.change(hour: 13).iso8601
        )
        expect(result[:success]).to be true
        expect(result[:has_conflicts]).to be true
        expect(result[:conflict_count]).to eq(1)
      end

      it 'handles API errors gracefully' do
        svc = described_class.new
        allow(svc).to receive(:available?).and_return(true)
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:use_ssl=)
        allow(http_double).to receive(:open_timeout=)
        allow(http_double).to receive(:read_timeout=)
        allow(http_double).to receive(:request).and_raise(StandardError.new("fail"))

        result = svc.check_booking_conflicts(
          venue_id: venue.id,
          start_time: 1.day.from_now.iso8601,
          end_time: (1.day.from_now + 1.hour).iso8601
        )
        expect(result[:success]).to be false
        expect(result[:answer]).to include("error")
      end
    end
  end
end
