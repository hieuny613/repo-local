FROM redhat/ubi8
RUN rm -rf /etc/yum.repos.d/*
ADD --chown=root:root key/* /etc/pki/entitlement/
ADD --chown=root:root repo/* /etc/yum.repos.d/
ADD --chown=root:root script/* /script/
RUN dnf repolist && \
    dnf update -y
RUN dnf install -y yum-utils createrepo parallel cronie vim tzdata 
ENV TZ=Asia/Ho_Chi_Minh
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone
COPY --chown=root:root crontab /etc/crontab
RUN chmod 0644 /etc/crontab
RUN touch /var/log/cron.log
RUN crontab /etc/crontab
RUN chmod +x /script/entrypoint.sh
ENTRYPOINT ["/script/entrypoint.sh"]
