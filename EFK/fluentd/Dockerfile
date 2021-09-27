# fluentd/Dockerfile
FROM fluentd
USER root
RUN ["gem", "install", "fluent-plugin-elasticsearch", "fluent-plugin-multi-format-parser"]
USER fluent
