require 'huginn_agent'

#HuginnAgent.load 'huginn_owm_onecall_agent/concerns/my_agent_concern'
HuginnAgent.register 'huginn_owm_onecall_agent/owm_onecall_agent'
HuginnAgent.register 'huginn_owm_onecall_agent/owm_event_stringifier_agent'
