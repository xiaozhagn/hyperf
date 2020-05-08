# Default Dockerfile
#
# @link     https://www.hyperf.io
# @document https://doc.hyperf.io
# @contact  group@hyperf.io
# @license  https://github.com/hyperf-cloud/hyperf/blob/master/LICENSE

FROM hyperf/hyperf:7.2-alpine-v3.9-cli
LABEL maintainer="Hyperf Developers <group@hyperf.io>" version="1.0" license="MIT"

# ---------- sshd service settings ----------
# 替换阿里云的源
# RUN echo "http://mirrors.aliyun.com/alpine/latest-stable/main/" > /etc/apk/repositories
# RUN echo "http://mirrors.aliyun.com/alpine/latest-stable/community/" >> /etc/apk/repositories
#  
#  # 同步时间
#   
#   # 更新源、安装openssh 并修改配置文件和生成key 并且同步时间
#   RUN apk update && \
#     apk add --no-cache openssh tzdata && \ 
#     cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
#     sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
#      ssh-keygen -t dsa -P "" -f /etc/ssh/ssh_host_dsa_key && \
#      ssh-keygen -t rsa -P "" -f /etc/ssh/ssh_host_rsa_key && \
#      ssh-keygen -t ecdsa -P "" -f /etc/ssh/ssh_host_ecdsa_key && \
#      ssh-keygen -t ed25519 -P "" -f /etc/ssh/ssh_host_ed25519_key && \
#      echo "root:admin" | chpasswd

##
# ---------- env settings ----------
##
# --build-arg timezone=Asia/Shanghai
ARG timezone

ENV TIMEZONE=${timezone:-"Asia/Shanghai"} \
    COMPOSER_VERSION=1.9.1 \
    APP_ENV=prod

# update
RUN set -ex \
    && apk update \
    # install composer
    && cd /tmp \
    && wget https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar \
    && chmod u+x composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    # show php version and extensions
    && php -v \
    && php -m \
    #  ---------- some config ----------
    && cd /etc/php7 \
    # - config PHP
    && { \
        echo "upload_max_filesize=100M"; \
        echo "post_max_size=108M"; \
        echo "memory_limit=1024M"; \
        echo "date.timezone=${TIMEZONE}"; \
    } | tee conf.d/99-overrides.ini \
    # - config timezone
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    # ---------- clear works ----------
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man \
    && echo -e "\033[42;37m Build Completed :).\033[0m\n"

WORKDIR /opt/www

# Composer Cache
# COPY ./composer.* /opt/www/
# RUN composer install --no-dev --no-scripts

COPY . /opt/www
RUN composer config  repo.packagist composer https://mirrors.aliyun.com/composer/
RUN composer install --no-dev -o

EXPOSE 9501
# 执行ssh启动命令
# CMD ["/usr/sbin/sshd", "-D"]
ENTRYPOINT ["php", "/opt/www/bin/hyperf.php", "start"]
