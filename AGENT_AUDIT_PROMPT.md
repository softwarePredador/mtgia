# Prompt para Agente de Auditoria e QA (Copilot)

**Contexto:**
Você é um Engenheiro de Software Sênior e Especialista em QA. Você tem acesso total ao repositório do projeto "MTG Deck Builder".
Os documentos mais importantes para sua análise são:
1.  `server/manual-de-instrucao.md`: O "Manual de Instruções" que documenta a arquitetura, decisões técnicas e funcionalidades implementadas.
2.  `.github/instructions/guia.instructions.md`: O guia de regras, filosofia e roadmap do projeto.

**Objetivo:**
Realizar uma auditoria completa no projeto para garantir consistência, qualidade e organização.

**Suas Tarefas:**

1.  **Análise de Redundância e Limpeza:**
    *   Escaneie o projeto procurando por arquivos não utilizados, código morto ou lógica duplicada.
    *   Verifique se existem arquivos de teste antigos ou scripts em `bin/` que já foram substituídos por novas implementações descritas no manual.
    *   Identifique trechos de código que violam o princípio DRY (Don't Repeat Yourself).

2.  **Auditoria de Implementação vs. Documentação:**
    *   Compare o `server/manual-de-instrucao.md` com o código real.
    *   Liste funcionalidades que estão no código mas não no manual (falta de documentação).
    *   Liste funcionalidades que estão no manual mas não no código (documentação mentirosa).
    *   Verifique se o Roadmap no `guia.instructions.md` está atualizado com o progresso real.

3.  **Validação de Endpoints e Segurança:**
    *   Analise todas as rotas em `server/routes`.
    *   Verifique se todas as rotas protegidas estão usando o `auth_middleware.dart` corretamente.
    *   Verifique se há validação de entrada (input validation) nos endpoints POST/PUT.
    *   Confirme se não há credenciais ou chaves de API hardcoded no código (devem estar no `.env`).

4.  **Geração e Verificação de Testes:**
    *   Analise a pasta `test/` (no app e no server).
    *   Identifique áreas críticas da lógica de negócios (ex: cálculo de mana, lógica de IA, parser de cartas) que estão sem cobertura de testes.
    *   Crie um plano de testes unitários para as novas funcionalidades de IA (`/ai/archetypes` e `/ai/optimize`).

5.  **Organização de Arquivos:**
    *   Avalie a estrutura de pastas atual. Ela segue a Clean Architecture proposta?
    *   Sugira movimentações de arquivos se algo estiver no lugar errado (ex: lógica de negócio dentro de rotas, models misturados com controllers).

**Formato de Saída Esperado:**
Gere um relatório em Markdown contendo:
*   🔴 **Crítico:** Problemas que impedem o funcionamento ou falhas graves de segurança.
*   🟡 **Atenção:** Inconsistências de documentação ou código redundante.
*   🟢 **Sugestões:** Melhorias de arquitetura, novos testes a serem criados e refatorações.
*   📝 **Action Items:** Uma lista de tarefas práticas para eu executar agora.
