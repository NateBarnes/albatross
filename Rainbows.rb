Rainbows! do
  use :EventMachine
  keepalive_timeout  3600*12
  worker_connections 180_000
  client_max_body_size nil
  client_header_buffer_size 512
end

worker_processes 8
stderr_path "./log/error.log"
stdout_path "./log/output.log"
