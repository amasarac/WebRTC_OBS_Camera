obs = obslua

function script_description()
    return "WebRTC streamer for OBS using OBS WebSocket API."
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "server", "WebSocket server URL", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "stream_key", "Stream key", obs.OBS_TEXT_DEFAULT)
    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "server", "ws://localhost:4444")
    obs.obs_data_set_default_string(settings, "stream_key", "")
end

function script_update(settings)
    server_url = obs.obs_data_get_string(settings, "server")
    stream_key = obs.obs_data_get_string(settings, "stream_key")
end

function script_load(settings)
    connect()
end

function connect()
    websocket_client = obs.obs_ws_client_create()
    obs.obs_ws_client_connect(websocket_client, server_url, false)
    obs.timer_add(send_frame, 33)
end

function send_frame()
    source = obs.obs_get_output_source(0)
    if source ~= nil then
        settings = obs.obs_source_get_settings(source)
        video_settings = obs.obs_data_get_array(settings, "video_settings")
        video_frame = obs.obs_video_info_alloc()
        obs.obs_video_info_from_settings(video_frame, video_settings)

        video_frame_data = obs.obs_source_get_video(source, video_frame)
        obs.obs_ws_client_send(websocket_client, stream_key, video_frame_data)

        obs.obs_video_info_free(video_frame)
        obs.obs_data_array_release(video_settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
end

function script_unload()
    obs.obs_ws_client_free(websocket_client)
end
