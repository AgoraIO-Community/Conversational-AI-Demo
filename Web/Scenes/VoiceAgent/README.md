# 🌟 Agora Conversational AI Engine Demo Application


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

 install node 22+ and git
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
# Use your preferred package manager to install dependencies: npm/yarn/pnpm/bun
# Using npm to install
npm i
# Using yarn to install
# npm install -g yarn
yarn
# Using pnpm to install
# npm install -g pnpm
pnpm i
# Using bun to install
# npm install -g bun
bun i
```

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
NEXT_PUBLIC_CUSTOM_LLM_SYSTEM_MESSAGES="<your-TTS-vendor>"
NEXT_PUBLIC_CUSTOM_LLM_MODEL="<your-LLM-model>"

#----------- TTS -----------
NEXT_PUBLIC_CUSTOM_TTS_VENDOR="<your-TTS-vendor>"
NEXT_PUBLIC_CUSTOM_TTS_PARAMS="<your-TTS-params>"
```

- Run the development server

```bash
bun dev
```


## 🗂️ Project Structure Overview

| Path                                          | Description                               |
| -------------------------------------------- | -------------------------------- |
| [api/](./src/app/api/)                       | Implementation of Conversational AI Engine API interfaces and data models |
| [app/page](./src/app/page.tsx)               | Main content of the page                       |
| [components/](./src/components/)             | Page components                          |
| [logger/](./src/lib/logger)                  | Logging                           |
| [services/rtc](./src/services/rtc.ts)        | Implementation related to RTC audio and video communication              |
| [type/rtc](./src/type/rtc.ts)                | Types and enumerations of Rtc     |


## 📚 Resources

- 📖 Check out our [Conversational AI Engine Documentation](https://doc.agora.io/doc/convoai/restful/landing-page) for more details
- 🧩 Visit [Agora SDK Examples](https://github.com/AgoraIO) for more tutorials and example code
- 👥 Explore high-quality repositories managed by the developer community in the [Agora Developer Community](https://github.com/AgoraIO-Community)
- 💬 If you have any questions, feel free to ask on [Stack Overflow](https://stackoverflow.com/questions/tagged/agora.io)

## 💡 Feedback

If you encounter any issues during integration or have suggestions for improvement:

- 🤖 Get help from intelligent customer service or contact technical support through [Agora Support](https://ticket.agora.io/form?type_id=&sdk_product=&sdk_platform=&sdk_version=&current=0&project_id=&call_id=&channel_name=)
- ✉️ Send an email to [support@agora.io](mailto:support@agora.io) for professional support

## 📜 License

This project is licensed under the MIT License.
