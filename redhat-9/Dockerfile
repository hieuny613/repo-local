FROM redhat/ubi9
RUN rm -rf /etc/yum.repos.d/*
ADD --chown=root:root key/* /etc/pki/entitlement/
ADD --chown=root:root repo/* /etc/yum.repos.d/
ADD --chown=root:root script/rsync-repo-redhat.sh /script/rsync-repo-redhat.sh
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
RUN bash /script/rsync-repo-redhat.sh
CMD ["/usr/sbin/crond", "-n"]