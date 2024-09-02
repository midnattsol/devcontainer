FROM ubuntu:22.04 as BUILDER
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    && apt-get clean

# Setup Google Cloud cli
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz && \
    tar -xvzf google-cloud-cli-linux-x86_64.tar.gz && \
    google-cloud-sdk/install.sh --usage-reporting=false --quiet

# Setup AWS Cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install -i /opt/aws
# ---------------------------------------------------
FROM ubuntu:22.04
ENV ZSH_CUSTOM="/home/dev/.oh-my-zsh/custom"

RUN apt update && apt install -y zsh git curl build-essential sudo vim unzip
RUN adduser dev --gecos "" --quiet --disabled-password  --shell /usr/bin/zsh && \
  echo "dev ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/adm-nopasswd  

USER dev
WORKDIR /home/dev
ENV ZSH_CUSTOM="/home/dev/.oh-my-zsh/custom"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    git clone https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting && \
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf && \
    $HOME/.fzf/install && \
    mkdir -p ./.local

COPY ./config/zshrc ./.zshrc
COPY --from=BUILDER /google-cloud-sdk ./.local/google-cloud-sdk
COPY --from=BUILDER /opt/aws /opt/aws

RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1 && \
    $HOME/.asdf/bin/asdf plugin-add terraform https://github.com/asdf-community/asdf-hashicorp.git && \
    $HOME/.asdf/bin/asdf plugin-add kubectl https://github.com/asdf-community/asdf-kubectl.git && \
    $HOME/.asdf/bin/asdf install kubectl 1.29.8 && \ 
    $HOME/.asdf/bin/asdf install terraform 1.5.7

ENTRYPOINT ["/usr/bin/zsh"]
