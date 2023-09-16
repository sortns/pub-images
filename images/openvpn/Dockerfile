# Original credit: https://github.com/kylemanna/docker-openvpn

FROM ubuntu:latest

LABEL maintainer="sortns@gmail.com"

RUN apt update -y && \
    apt install -y openvpn easy-rsa && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/
    # rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

# Needed by scripts
ENV OPENVPN=/etc/openvpn
ENV EASYRSA=/usr/share/easy-rsa \
    EASYRSA_CRL_DAYS=3650 \
    EASYRSA_PKI=$OPENVPN/pki

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp

CMD ["ovpn_run"]

ADD ./images/openvpn/bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# # Add support for OTP authentication using a PAM module
# ADD ./images/openvpn/otp/openvpn /etc/pam.d/