---

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![WebSockets](https://img.shields.io/badge/WebSockets-black?style=for-the-badge&logo=socket.io&logoColor=white)
![Build Status](https://img.shields.io/badge/build-passing-brightgreen?style=for-the-badge)

*Um aplicativo móvel de xadrez multiplayer com atualizações em tempo real e interface fluida.*

</div>

---

Este é o frontend oficial do **Chess Multiplayer**, desenvolvido em **Flutter**. Ele oferece um tabuleiro interativo de xadrez com suporte a validação de regras do jogo e comunicação síncrona via WebSockets com o backend.

Enquanto aplicativos tradicionais baseiam-se em chamadas REST pontuais, este projeto implementa um **serviço de WebSocket** persistente, essencial para a experiência de jogo online sem delays.

---

## Diferenciais Arquiteturais

A força deste projeto reside na separação entre a camada de renderização do tabuleiro e a camada de comunicação:

| Componente | Problema Resolvido | Aplicação no Projeto |
| :--- | :--- | :--- |
| **WebSocket Service** | Conexão Persistente | Gerencia a conexão com o servidor, envio de lances e recebimento de atualizações de FEN em tempo real. |
| **Padrão Repository/Service** | Acoplamento Lógico | A lógica de rede e regras locais (`PreMoveService`, `WebSocketService`) não estão misturadas nos Widgets da UI. |
| **Gestão de Estado** | Atualização do Tabuleiro | Atualizações reativas focadas apenas nos widgets que dependem do estado atual da partida e do relógio. |
| **Custom Painters** | Renderização Customizada | Uso de `CustomPainter` (ex: `ChessBackgroundPainter`) para gráficos otimizados e temas de tabuleiro modernos. |

---

## 🛠 Tecnologias Utilizadas
<div align="left">
  <img src="https://img.shields.io/badge/Flutter-SDK_3%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/WebSockets-Real_Time-black?style=for-the-badge&logo=socket.io&logoColor=white" />
  <img src="https://img.shields.io/badge/Groq-AI_LLaMA_3-F55036?style=for-the-badge&logo=openai&logoColor=white" />
</div>

---

## Estrutura do Projeto
```text
lib/
├── core/
│   └── services/           # WebSocketService e ApiService
├── features/
│   ├── auth/               # Telas de login e registro
│   ├── home/               # Dashboard e histórico de partidas
│   └── partida/            # Core do jogo
│       ├── models/         # Modelos de domínio (PreMove, Match)
│       ├── services/       # PreMoveService e lógica local
│       └── widgets/        # TabuleiroWidget, RelogioWidget, PainelFimPartida
├── shared/
│   ├── theme/              # Temas, cores e tipografia (AppTheme)
│   └── widgets/            # Componentes visuais genéricos (GlassCard, LoadingButton)
└── main.dart               # Entry point da aplicação
```

---

### Pré-requisitos
* **Flutter SDK 3.0+**
* **Dart 3.0+**
* Um emulador Android/iOS ou dispositivo físico (ou via Web).

### Configuração
1. Clone o repositório.
2. Instale as dependências:
```bash
flutter pub get
```
3. Execute o projeto:
```bash
flutter run
```

### Usuário de Teste (Base)
Para facilitar os testes sem a necessidade de criar uma conta, o backend injeta automaticamente o seguinte usuário na inicialização:
- **Email:** `admin@email.com`
- **Senha:** `123456`

---

- ♟️ **Partidas em Tempo Real** — Jogue contra outros usuários online instantaneamente.
- ⏱️ **Modo de Relógio** — Diferentes modos de tempo com sincronização automática do servidor.
- 🧠 **Análise por Inteligência Artificial** — Relatórios pós-partida gerados pelo modelo LLaMA 3 via Groq, com notas de desempenho, identificação de aberturas e dicas táticas.
- 🎨 **Interface Premium** — Design limpo com efeitos de *Glassmorphism* e componentes animados nativos.
- 🔁 **Revanche** — Sistema de solicitação rápida de revanche após o fim da partida.
