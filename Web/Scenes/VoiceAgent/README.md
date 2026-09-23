# 🌟 Conversational AI Demo


The Agora Conversational AI Engine redefines human-AI interaction interfaces, breaking through traditional text interactions to achieve highly realistic, natural, and smooth real-time voice conversations, allowing AI to truly "speak". It is suitable for innovative scenarios such as:

- 🤖 Intelligent Assistants
- 💞 Emotional Companionship
- 🗣️ Language Tutor
- 🎧 Intelligent Customer Service
- 📱 Smart Hardware
- 🎮 Immersive Game NPCs

## 🚀 Quick Start

This section mainly introduces how to quickly run the Agora Conversational AI Engine demo application project.

### 💻 Environment Setup

Install Node.js 22+, Git, and Bun 1.4.0.
```bash
For Linux/MacOS, you can execute directly in the terminal
# For Windows, it is recommended to use Windows WSL
# https://github.com/nvm-sh/nvm?tab=readme-ov-file#install--update-script
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Install Node.js 22+
nvm install 22
nvm use 22

# Install Git (MacOS comes with Git, no need to install)
# Debian/Ubuntu
sudo apt install git-all

# Fedora/RHEL/CentOS
sudo dnf install git-all
```

### ⚙️ Running the Project


1. Follow [Get started with Agora](https://docs-preview.agora.io/en/conversational-ai/get-started/manage-agora-account) to get the **App ID** and **App Certificate** and enable the **Conversational AI** service.
2. Follow [Generate Customer ID and Customer Secret](https://docs.agora.io/en/conversational-ai/rest-api/restful-authentication#generate-customer-id-and-customer-secret) to get the **Basic Auth Key** and **Basic Auth Secret**.
3. Get LLM configuration information from LLM vendor.
4. Get TTS configuration information from TTS vendor.
  
#### 1.6 Configure the Project

- Install dependencies

```bash
# Run from the repository root
cd Web/Scenes/VoiceAgent
npm install -g bun@1.4.0
bun install --frozen-lockfile
```

The app consumes the public npm package `agora-agent-client-toolkit`, pinned to `2.10.0`. The complete dependency graph is locked in `bun.lock`; installation and builds only require this repository. npm/pnpm can also install from `package.json`; project validation and reproducible installs use Bun.

Dependency installation also downloads Toolkit; no local `file:`/`link:` dependency or separate Toolkit build is needed. `src/conversational-ai-api/` contains only Demo helpers and legacy subtitle support. Import public APIs from `agora-agent-client-toolkit`.

- Set environment variables

```bash
cp .env.example .env.local
```

```
#----------- AppId --------------
AGORA_APP_ID=<Agora App ID>
AGORA_APP_CERT=<Agora App Certificate>

#----------- Basic Auth ---------------
AGENT_BASIC_AUTH_KEY=<Agora RESTful API KEY>
AGENT_BASIC_AUTH_SECRET=<Agora RESTful API SECRET>

#----------- LLM -----------
NEXT_PUBLIC_CUSTOM_LLM_URL="<your-LLM-url>"
NEXT_PUBLIC_CUSTOM_LLM_KEY="<your-LLM-key>"
NEXT_PUBLIC_CUSTOM_LLM_SYSTEM_MESSAGES="<your-LLM-system-messages>"
NEXT_PUBLIC_CUSTOM_LLM_PARAMS="<your-LLM-params>"

#----------- TTS -----------
NEXT_PUBLIC_CUSTOM_TTS_VENDOR="<your-TTS-vendor>"
NEXT_PUBLIC_CUSTOM_TTS_PARAMS="<your-TTS-params>"
```

- Run the development server

```bash
bun run dev
```

### Toolkit integration and validation

- Toolkit provides public APIs, state events, transcripts, and metrics parsing. See the [Toolkit integration guide](src/conversational-ai-api/README.md).
- The Demo owns RTC/RTM initialization, audio capture, legacy subtitles, and report rendering/upload. On-device AINS is disabled by default and is enabled only when both developer mode and the AINS toggle are on.
- Normal and SIP calls await Toolkit initialization. Call cleanup destroys Toolkit before disconnecting RTC/RTM.

```bash
bun run test
bun run typecheck
bun run build
bun run start
```

When upgrading Toolkit, update its exact version and `bun.lock` together, then rerun these checks. Automated builds use `bun install --frozen-lockfile` to download the public release package.


## 🗂️ Project Structure Overview

| Path                                          | Description                               |
| -------------------------------------------- | -------------------------------- |
| [api/](./src/app/api/)                       | Implementation of Conversational AI Engine API interfaces and data models |
| [app/page](./src/app/page.tsx)               | Main content of the page                       |
| [components/](./src/components/)             | Page components                          |
| [logger/](./src/lib/logger)                  | Logging                           |
| [type/rtc](./src/type/rtc.ts)                | Types and enumerations of Rtc     |


## 📚 Resources

- 📖 Check out our [Conversational AI Engine Documentation](https://doc.agora.io/doc/convoai/restful/landing-page) for more details
- 🧩 Visit [Agora SDK Examples](https://github.com/AgoraIO) for more tutorials and example code
- 👥 Explore high-quality repositories managed by the developer community in the [Agora Developer Community](https://github.com/AgoraIO-Community)
- 💬 If you have any questions, feel free to ask on [Stack Overflow](https://stackoverflow.com/questions/tagged/agora.io)

## 💡 Feedback

- 🤖 If you have any problems or suggestions regarding the sample projects, we welcome you to file an issue.

## 📜 License

This project is licensed under the MIT License.
