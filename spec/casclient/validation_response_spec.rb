require 'spec_helper'
require 'casclient/responses.rb'

describe CASClient::ValidationResponse do
  context "when parsing extra attributes as raw" do
    let(:response_text) do
<<RESPONSE_TEXT
<cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
  <cas:authenticationSuccess>
    <cas:attributes>
      <cas:name>Jimmy Bob</cas:name>
      <cas:status><![CDATA[stuff
]]></cas:status>
      <cas:yaml><![CDATA[--- true
]]></cas:yaml>
      <cas:json><![CDATA[{"id":10529}]]></cas:json>
    </cas:attributes>
  </cas:authenticationSuccess>
</cas:serviceResponse>
RESPONSE_TEXT
    end

    subject { CASClient::ValidationResponse.new response_text, :encode_extra_attributes_as => :raw }

    it "sets text attributes to their string value" do
      expect(subject.extra_attributes["name"]).to eq("Jimmy Bob")
    end

    it "preserves whitespace for CDATA" do
      expect(subject.extra_attributes["status"]).to eq("stuff\n")
    end

    it "passes yaml through as is" do
      expect(subject.extra_attributes["yaml"]).to eq("--- true\n")
    end
    it "passes json through as is" do
      expect(subject.extra_attributes["json"]).to eq("{\"id\":10529}")
    end
  end

  context "when parsing extra attributes as yaml" do
    let(:response_text) do
<<RESPONSE_TEXT
<cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
  <cas:authenticationSuccess>
    <cas:attributes>
      <cas:name>Jimmy Bob</cas:name>
      <cas:status><![CDATA[stuff
]]></cas:status>
      <cas:truthy><![CDATA[--- true
]]></cas:truthy>
      <cas:falsy><![CDATA[#{false.to_yaml}]]></cas:falsy>
    </cas:attributes>
  </cas:authenticationSuccess>
</cas:serviceResponse>
RESPONSE_TEXT
    end

    subject { CASClient::ValidationResponse.new response_text, :encode_extra_attributes_as => :yaml }

    it "sets text attributes to their string value" do
      expect(subject.extra_attributes["name"]).to eq("Jimmy Bob")
    end

    it "sets the value of boolean attributes to their boolean value" do
      expect(subject.extra_attributes["falsy"]).to eq(false)
      expect(subject.extra_attributes["truthy"]).to eq(true)
    end
  end

  context "when parsing extra attributes as JSON" do
    let(:response_text) do
<<RESPONSE_TEXT
<cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
  <cas:authenticationSuccess>
    <cas:attributes>
      <cas:first_name>Jack</cas:first_name>
      <cas:last_name>92.5</cas:last_name>
      <cas:mobile_phone></cas:mobile_phone>
      <cas:global_roles><![CDATA[]]></cas:global_roles>
      <cas:foo_data><![CDATA[[{"id":10529}]]]></cas:foo_data>
      <cas:food_data><![CDATA[{"id":10529}]]></cas:food_data>
      <cas:allegedly_yaml>- 10</cas:allegedly_yaml>
      <cas:truthy><![CDATA[--- true
]]></cas:truthy>
      <cas:falsy><![CDATA[--- false
]]></cas:falsy>
    </cas:attributes>
  </cas:authenticationSuccess>
</cas:serviceResponse>
RESPONSE_TEXT
    end

    subject { CASClient::ValidationResponse.new response_text, :encode_extra_attributes_as => :json }

    it "sets the value of non-CDATA escaped empty attribute to nil" do
      expect(subject.extra_attributes["mobile_phone"]).to be_nil
    end

    it "sets the value of CDATA escaped empty attribute to nil" do
      expect(subject.extra_attributes["global_roles"]).to be_nil
    end

    it "sets the value of literal attributes to their value" do
      expect(subject.extra_attributes["first_name"]).to eq("Jack")
    end

    it "sets the value of JSON attributes containing Arrays to their parsed value" do
      expect(subject.extra_attributes["foo_data"][0]["id"]).to eq(10529)
    end

    it "sets the value of JSON attributes containing Hashes to their parsed value" do
      expect(subject.extra_attributes["food_data"]["id"]).to eq(10529)
    end

    it "sets non-hash attributes as strings" do
      expect(subject.extra_attributes["last_name"]).to be_a_kind_of String
    end

    it "sets the value of attributes which are not valid JSON but are valid YAML to their literal value" do
      expect(subject.extra_attributes["allegedly_yaml"]).to eq('- 10')
    end
  end

  context "When parsing extra attributes from xml attributes" do
    let(:response_text) do
<<RESPONSE_TEXT
<?xml version="1.0" encoding="UTF-8"?>
<cas:serviceResponse xmlns:cas="http://www.yale.edu/tp/cas">
  <cas:authenticationSuccess>
    <cas:user>myuser</cas:user>
    <cas:attribute name="username" value="myuser"/>
    <cas:attribute name="name" value="My User"/>
    <cas:attribute name="email" value="myuser@mail.example.com"/>
  </cas:authenticationSuccess>
</cas:serviceResponse>
RESPONSE_TEXT
    end

    subject { CASClient::ValidationResponse.new response_text }

    it "sets attributes for other type of format" do
      expected = {"username" => "myuser", "name" => 'My User', "email" => 'myuser@mail.example.com'}
      expect(subject.user).to eq('myuser')
      expect(subject.extra_attributes).to eq(expected)
    end
  end
end
