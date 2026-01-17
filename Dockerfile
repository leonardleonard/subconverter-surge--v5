FROM alpine:3.16 AS builder
LABEL maintainer="Surge 5 Support"
ARG THREADS="4"

# 安装构建依赖
WORKDIR /build
RUN set -xe && \
    apk add --no-cache --virtual .build-tools \
        git g++ build-base linux-headers cmake python3 && \
    apk add --no-cache --virtual .build-deps \
        curl-dev rapidjson-dev pcre2-dev yaml-cpp-dev

# 构建 QuickJS（本地已有兼容性修复）
RUN git clone https://github.com/ftk/quickjspp --depth=1 && \
    cd quickjspp && \
    git submodule update --init && \
    cmake -DCMAKE_BUILD_TYPE=Release . && \
    make quickjs -j $THREADS && \
    install -d /usr/lib/quickjs/ && \
    install -m644 quickjs/libquickjs.a /usr/lib/quickjs/ && \
    install -d /usr/include/quickjs/ && \
    install -m644 quickjs/quickjs.h quickjs/quickjs-libc.h /usr/include/quickjs/ && \
    install -m644 quickjspp.hpp /usr/include

# 构建 libcron
RUN cd /build && \
    git clone https://github.com/PerMalmberg/libcron --depth=1 && \
    cd libcron && \
    git submodule update --init && \
    cmake -DCMAKE_BUILD_TYPE=Release . && \
    make libcron -j $THREADS && \
    install -m644 libcron/out/Release/liblibcron.a /usr/lib/ && \
    install -d /usr/include/libcron/ && \
    install -m644 libcron/include/libcron/* /usr/include/libcron/ && \
    install -d /usr/include/date/ && \
    install -m644 libcron/externals/date/include/date/* /usr/include/date/

# 构建 toml11
RUN cd /build && \
    git clone https://github.com/ToruNiina/toml11 --branch="v3.7.1" --depth=1 && \
    cd toml11 && \
    cmake -DCMAKE_CXX_STANDARD=11 . && \
    make install -j $THREADS

# 复制 subconverter-surge--v5 源码（支持 Surge 5）
COPY . /subconverter

# 使用本地修复过的 quickjspp.hpp（包含兼容性修复）
RUN cp /subconverter/include/quickjspp.hpp /usr/include/quickjspp.hpp

# 应用 QuickJS 兼容性补丁
RUN cd /subconverter && \
    if [ -f quickjs-compat.patch ]; then \
        patch -p1 < quickjs-compat.patch || echo "Patch already applied or not needed"; \
    fi

# 构建（跳过规则更新，避免网络/认证问题）
RUN cd /subconverter && \
    python3 -m ensurepip && \
    python3 -m pip install gitpython && \
    (python3 scripts/update_rules.py -c scripts/rules_config.conf || echo "Warning: Rules update failed, using existing rules") && \
    cmake -DCMAKE_BUILD_TYPE=Release . && \
    make -j $THREADS

# 构建最终镜像
FROM alpine:3.16
LABEL maintainer="Surge 5 Support"
LABEL description="Subconverter with Surge 5 IOS & MacOS support"
LABEL version="1.0-surge5"

# 安装运行时依赖
RUN apk add --no-cache pcre2 libcurl yaml-cpp

# 从构建阶段复制文件
COPY --from=builder /subconverter/subconverter /usr/bin/
COPY --from=builder /subconverter/base /base/

# 设置工作目录
WORKDIR /base

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:25500/version || exit 1

# 暴露端口
EXPOSE 25500/tcp

# 启动服务
CMD ["subconverter"]
