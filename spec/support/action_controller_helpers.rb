require 'action_pack'

module ActionControllerHelpers

  def mock_controller_with_session(request = nil, session={})

    query_parameters = {:ticket => "bogusticket", :renew => false}
    parameters = query_parameters.dup

    #TODO this really need to be replaced with a "real" rails controller
    request ||= mock_post_request
    allow(request).to receive_messages({:query_parameters => query_parameters})
    allow(request).to receive_messages({:path_parameters => {}})
    controller = double("Controller")
    allow(controller).to receive_messages({:session => session})
    allow(controller).to receive_messages({:request => request})
    allow(controller).to receive_messages({:url_for => "bogusurl"})
    allow(controller).to receive_messages({:query_parameters => query_parameters})
    allow(controller).to receive_messages({:path_parameters => {}})
    allow(controller).to receive_messages({:parameters => parameters})
    allow(controller).to receive_messages({:params => parameters})
    controller
  end

  def mock_post_request
      mock_request = double("request")
      allow(mock_request).to receive_messages({:post? => true})
      allow(mock_request).to receive_messages({:session_options => Hash.new })
      allow(mock_request).to receive_messages({:headers => Hash.new })
      mock_request
  end
end
