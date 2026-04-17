# OpenClaw Overview

> Sources: OpenClaw Lab, Unknown
> Raw: [OpenClaw Documentation Overview](../../raw/openclaw/2026-04-16-openclaw-documentation-overview.md)

## Overview

OpenClaw is an open-source AI assistant platform built on Anthropic's Claude Agent SDK. It provides a gateway-based architecture for deploying AI agents across multiple communication channels — including WhatsApp, Telegram, Discord, iMessage, and Slack — with configurable tools, memory systems, and multi-model provider support.

## Architecture

OpenClaw is structured around four core components:

**Gateway** — The central process that manages all channels and AI interactions. It can be deployed locally or remotely and acts as the coordination layer between user channels and the underlying AI agent.

**Agent** — The intelligent core of the system, defined through workspace files (Identity, Soul, Tools, Skills) that specify the agent's capabilities, memory configuration, and interaction style. The workspace-file approach makes agents declarative and version-controllable.

**Channels** — Integration adapters connecting the gateway to external platforms. Supported channels include WhatsApp, Telegram, Discord, iMessage, Slack, and others, enabling the same agent to operate across multiple communication surfaces simultaneously.

**Tools** — Runtime capabilities available to the agent: browser control, file operations, system commands, and task automation. Tools are the mechanism by which the agent takes action in the world.

A fifth component, **Providers**, forms the model layer. OpenClaw supports Anthropic Claude, OpenAI, locally-run models via Ollama, and Chinese AI providers, with failover mechanisms between them.

## Key Capabilities

**Automation** — Agents can be triggered by cron schedules, webhooks, polls, and Gmail PubSub subscriptions, enabling autonomous background workflows without user initiation.

**Multi-agent Routing** — The platform supports sub-agent management and routing, allowing complex tasks to be delegated across a hierarchy of specialized agents.

**Memory Systems** — Configurable memory with search, read, fallback, and injection-limit controls. Memory persists across sessions and is injected into context at runtime.

**Session Management** — Concurrency handling and session pruning keep resource usage bounded when multiple users or channels are active simultaneously.

**Security** — Sandbox environments, tool policies, and elevated mode execution provide layered controls over what agents can and cannot do.

## Documentation Structure

The OpenClaw docs are organized into five paths targeting different user levels:

1. **Getting Started** — Quick start guides, installation, and CLI reference
2. **Core Concepts** — Architecture, channel integration, provider configuration
3. **Advanced Topics** — Agent customization, tool implementation, platform-specific guidance
4. **Production** — Gateway configuration, remote access, security hardening
5. **Reference** — Configuration details, HTTP APIs, templates, glossary

Community support is available via GitHub Discussions alongside FAQ and troubleshooting guides.
