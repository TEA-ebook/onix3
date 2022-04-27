require 'spec_helper'
require 'zlib'
require 'stringio'
require 'nokogiri'

describe Onix3::Parser::Divider do
  
  let(:simple_onix) {
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<ONIXMessage release="3.0" xmlns="http://ns.editeur.org/onix/3.0/reference">' +
    '<Header>H</Header>' +
    '<Product>P</Product>' +
    '<Product>P</Product>' +
    '</ONIXMessage>'
  }

  let(:simple_onix_ns) {
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<onix:ONIXMessage release="3.0" xmlns:onix="http://ns.editeur.org/onix/3.0/reference">' +
    '<onix:Header>H</onix:Header>' +
    '<onix:Product>P</onix:Product>' +
    '<onix:Product>P</onix:Product>' +
    '</onix:ONIXMessage>'
  }

  let(:simple_onix_without_header) {
    '<?xml version="1.0" encoding="UTF-8"?>' +
        '<ONIXMessage release="3.0" xmlns="http://ns.editeur.org/onix/3.0/reference">' +
        '<Product>P1</Product>' +
        '<Product>P2</Product>' +
        '<Product>P3</Product>' +
        '</ONIXMessage>'
  }

  let(:short_tags_onix) do
    '<?xml version="1.0" encoding="UTF-8"?>
    <ONIXmessage xmlns="http://ns.editeur.org/onix/3.0/short" release="3.0">
      <header>
        <sender>
          <x298>Test sender</x298>
        </sender>
        <x307>20211011T110727+02:00</x307>
      </header>
      <product>
        <a001>p1</a001>
        <productidentifier>
          <b221>03</b221>
          <b244>9780000000001</b244>
        </productidentifier>
      </product>
      <product>
        <a001>p2</a001>
        <productidentifier>
          <b221>03</b221>
          <b244>9780000000002</b244>
        </productidentifier>
      </product>
    </ONIXmessage>'
  end

  describe "#document_for_products" do

    it "should have ONIXMessage as root" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      doc = d.document_for_products([])
      expect(doc).to match(/<\w+/)
      expect(doc.match(/<\w+/)[0]).to eq("<ONIXMessage")
    end

    it "should have header" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      doc = d.document_for_products([])
      expect(doc).to match(/<Header[^>]*>H<\/Header>/)
    end

    it "should yield valid xml" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      doc = d.document_for_products([])
      p = Nokogiri.XML(doc) { |config| config.nonet }
      expect(p).to be_truthy
    end

    it "should contain products" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      doc = d.document_for_products(["<Product>1</Product>", "<Product>2</Product>"])
      expect(doc).to match(/<Product>1<\/Product>/)
      expect(doc).to match(/<Product>2<\/Product>/)
    end      

  end

  describe "#document_end" do

    it "should close ONIXMessage tag" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      expect(d.document_end).to eq("</ONIXMessage>")
    end

  end

  describe "#document_start" do

    it "should have ONIXMessage as root" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      start = d.document_start
      expect(start).to match(/<\w+/)
      expect(start.match(/<\w+/)[0]).to eq("<ONIXMessage")
    end

    it "should have header" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      start = d.document_start
      expect(start).to match(/<Header[^>]*>H<\/Header>/)
    end

    it "should yield valid xml" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      start = d.document_start
      p = Nokogiri.XML(start + d.document_end) { |config| config.nonet }
      expect(p).to be_truthy
    end

  end

  describe "#each_product" do

    it "should return the number of products" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      res = d.each_product do |doc|
        # nothing
      end
      expect(res).to eq(2)
    end

    it "should copy the exact product" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      d.each_product_document do |doc|
        expect(doc).to match(/<Product[^>]*>P<\/Product>/)
      end
    end

  end

  describe "#each_product_document" do    

    it "should return the number of products" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      res = d.each_product_document do |doc|
        # nothing
      end
      expect(res).to eq(2)
    end

    it "should copy the exact header" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      res = d.each_product_document do |doc|
        expect(doc).to match(/<Header[^>]*>H<\/Header>/)
      end
    end

    it "should allow a namespace for the root tag" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix_ns))
      res = d.each_product_document do |doc|
        expect(doc.index(">H</")).to be > 0
      end
    end

    it "should allow a namespaced attribute for the root tag" do
      skip "Nokogiri issue 843" # https://github.com/sparklemotion/nokogiri/issues/843
    end

    it "should copy the exact product" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      d.each_product_document do |doc|
        expect(doc).to match(/<Product[^>]*>P<\/Product>/)
      end
    end

    it "should yield valid xml" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix))
      d.each_product_document do |doc|
        p = Nokogiri.XML(doc) { |config| config.nonet }
        expect(p).to be_truthy
      end
    end

    context "with short tags" do
      subject(:divider) { Onix3::Parser::Divider.new(StringIO.new(short_tags_onix)) }

      it "should return the number of products" do
        res = divider.each_product_document do |doc|
          # nothing
        end

        expect(res).to eq(2)
      end

      it "should copy the exact header" do
        res = divider.each_product_document do |doc|
          expect(doc).to match(%r{
            <header[^>]*>\s*
              <sender>\s*<x298>Test\ sender</x298>\s*</sender>\s*
              <x307>20211011T110727\+02:00</x307>\s*
            </header>
            }xm)
        end
      end

      it "should copy the exact product, and no other one" do
        n = 0

        divider.each_product_document do |doc|
          n += 1

          expect(doc).to match(%r{
            <product[^>]*>\s*
                <a001>p#{n}</a001>\s*
                <productidentifier>\s*
                    <b221>03</b221>\s*
                    <b244>978000000000#{n}</b244>\s*
                </productidentifier>\s*
            </product>
            }xm)

            expect(doc).to match(/\b978000000000#{n}\b/)
            expect(doc).not_to match(/\b978000000000#{n - 1}\b/)
            expect(doc).not_to match(/\b978000000000#{n + 1}\b/)
        end
      end

      it "should yield valid xml" do
        divider.each_product_document do |doc|
          p = Nokogiri.XML(doc) { |config| config.nonet }
          expect(p).to be_truthy
        end
      end
    end
  end

  describe "with a file which has no header" do
    it "should return the right number of products" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix_without_header))
      res = d.each_product_document do |doc|
        # nothing
      end
      expect(res).to eq(3)
    end

    it "should have no header" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix_without_header))
      res = d.each_product_document do |doc|
        expect(doc.index(">H</")).to be_nil
      end
    end

    it "should copy the exact product" do
      d = Onix3::Parser::Divider.new(StringIO.new(simple_onix_without_header))
      d.each_product_document do |doc|
        expect(doc).to match(/<Product[^>]*>P[1|2|3]<\/Product>/)
      end
    end
  end

end
