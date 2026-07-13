FROM mcr.microsoft.com/devcontainers/base:bookworm

ARG TYPST_VERSION=0.13.0
ARG LIBERTINUS_VERSION=7.051

RUN apt-get update && apt-get install -y --no-install-recommends \
        fonts-dejavu-core \
        fonts-dejavu-extra \
        fontconfig \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Install the typst CLI, pinned to the compiler version in typst.toml.
# Detected via `uname -m` rather than Docker's $TARGETARCH build-arg, since
# that's only populated by BuildKit/buildx, not the legacy builder.
RUN case "$(uname -m)" in \
        x86_64) ARCH=x86_64 ;; \
        aarch64) ARCH=aarch64 ;; \
        *) echo "Unsupported architecture: $(uname -m)" >&2 && exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${ARCH}-unknown-linux-musl.tar.xz" -o /tmp/typst.tar.xz \
    && tar -xf /tmp/typst.tar.xz -C /tmp \
    && install -m 755 "/tmp/typst-${ARCH}-unknown-linux-musl/typst" /usr/local/bin/typst \
    && rm -rf /tmp/typst*

# Install Libertinus Serif, used by src/elements/exam.typ and exam-new.typ.
# Not packaged for Debian stable/testing, so fetch it from upstream.
RUN curl -fsSL "https://github.com/alerque/libertinus/releases/download/v${LIBERTINUS_VERSION}/Libertinus-${LIBERTINUS_VERSION}.zip" -o /tmp/libertinus.zip \
    && mkdir -p /usr/local/share/fonts/libertinus \
    && unzip -j /tmp/libertinus.zip "Libertinus-${LIBERTINUS_VERSION}/static/OTF/*.otf" -d /usr/local/share/fonts/libertinus \
    && rm -rf /tmp/libertinus.zip \
    && fc-cache -f
