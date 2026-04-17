# OpenClaw Documentation Overview

> Source: https://openclawlab.com/en/docs/
> Collected: 2026-04-16
> Published: Unknown

## What is OpenClaw?

OpenClaw is an open-source AI coding assistant built on Anthropic's Claude Agent SDK. The platform provides a comprehensive framework for building, deploying, and managing AI agents across multiple communication channels.

## Core Architecture Components

**Gateway**: OpenClaw employs a gateway architecture where a central Gateway process manages all channels and AI interactions, supporting both local and remote deployment configurations.

**Agent**: The Agent represents the core AI assistant, defined through workspace files including Identity, Soul, Tools, and Skills that specify capabilities, memory, and interaction patterns.

**Channels**: Integration points supporting WhatsApp, Telegram, Discord, iMessage, Slack, and numerous other platforms for user interaction.

**Tools**: Agent capabilities enabling browser control, file operations, system commands, and automation tasks.

**Providers**: Configuration layer supporting Anthropic Claude, OpenAI, local models via Ollama, and Chinese AI providers.

## Documentation Organization

The documentation is structured into five primary paths:

1. **Getting Started**: Quick start guides, installation methods, and CLI command references
2. **Core Concepts**: Architecture details, channel integration, and provider configuration
3. **Advanced Topics**: Agent customization, tool implementation, platform-specific guidance
4. **Production**: Gateway configuration, remote access, and security hardening
5. **Reference**: Configuration details, HTTP APIs, templates, and glossary

## Key Features

The platform emphasizes "concurrency, approvals, memory, and operational excellence," supporting multi-agent routing, session management, context engineering, and robust model failover mechanisms.

Additional capabilities include:

- **Automation**: Cron jobs, webhooks, polls, and Gmail PubSub integration
- **Security**: Sandbox environments, tool policies, and elevated mode execution
- **Multi-agent**: Routing capabilities and sub-agent management
- **Memory Systems**: Search, read, fallback, and injection limit controls
- **Session Management**: Concurrency handling and session pruning
- **Model Support**: Anthropic Claude, OpenAI, local models (Ollama), and Chinese models

## Getting Help

Resources include FAQ documentation, troubleshooting guides, and GitHub Discussions for community support.
