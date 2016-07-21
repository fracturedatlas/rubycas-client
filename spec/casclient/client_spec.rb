require 'spec_helper'

describe CASClient::Client do
  let(:client)     { CASClient::Client.new(:login_url => login_url, :cas_base_url => '')}
  let(:login_url)  { "http://localhost:3443/"}
  let(:uri)        { URI.parse(login_url) }
  let(:session)    { double('session', :use_ssl= => true, :verify_mode= => true) }

  context "https connection" do
    let(:proxy)      { double('proxy', :new => session) }

    before :each do
      allow(Net::HTTP).to receive_messages({:Proxy => proxy})
    end

    it "sets up the session with the login url host and port" do
      expect(proxy).to receive(:new).with('localhost', 3443).and_return(session)
      client.send(:https_connection, uri)
    end
    
    it "sets up the proxy with the known proxy host and port" do
      client = CASClient::Client.new(:login_url => login_url, :cas_base_url => '', :proxy_host => 'foo', :proxy_port => 1234)
      expect(Net::HTTP).to receive(:Proxy).with('foo', 1234).and_return(proxy)
      client.send(:https_connection, uri)
    end
  end
  
  context "cas server requests" do
    let(:response)   { double('response', :body => 'HTTP BODY', :code => '200') }
    let(:connection) { double('connection', :get => response, :post => response, :request => response) }

    before :each do
      allow(client).to receive(:https_connection).and_return(session)
      allow(session).to receive(:start).and_yield(connection)
    end
    
    context "cas server is up" do
      it "returns false if the server cannot be connected to" do
        allow(connection).to receive(:get).and_raise(Errno::ECONNREFUSED)
        expect(client.cas_server_is_up?).to eq(false)
      end
    
      it "returns false if the request was not a success" do
        allow(response).to receive_messages({:kind_of? => false})
        expect(client.cas_server_is_up?).to eq(false)
      end
      
      it "returns true when the server is running" do
        allow(response).to receive_messages({:kind_of? => true})
        expect(client.cas_server_is_up?).to eq(true)
      end
    end
    
    context "request login ticket" do
      it "raises an exception when the request was not a success" do
        allow(session).to receive(:post).with("/Ticket", ";").and_return(response)
        allow(response).to receive_messages({:kind_of? => false})
        expect(lambda {
          client.request_login_ticket
        }).to raise_error(CASClient::CASException)
      end
      
      it "returns the response body when the request is a success" do
        allow(session).to receive(:post).with("/Ticket", ";").and_return(response)
        allow(response).to receive_messages({:kind_of? => true})
        expect(client.request_login_ticket).to eq("HTTP BODY")
      end
    end
    
    context "request cas response" do
      let(:validation_response) { double('validation_response') }
      
      it "should raise an exception when the request is not a success or 422" do
        allow(response).to receive_messages({:kind_of? => false})
        expect(lambda {
          client.send(:request_cas_response, uri, CASClient::ValidationResponse)
        }).to raise_error(RuntimeError)
      end
      
      it "should return a ValidationResponse object when the request is a success or 422" do
        allow(CASClient::ValidationResponse).to receive(:new).and_return(validation_response)
        allow(response).to receive_messages({:kind_of? => true})
        expect(client.send(:request_cas_response, uri, CASClient::ValidationResponse)).to eq(validation_response)
      end
    end
    
    context "submit data to cas" do
      it "should return an HTTPResponse" do
        expect(client.send(:submit_data_to_cas, uri, {})).to eq(response)
      end
    end
  end
end
