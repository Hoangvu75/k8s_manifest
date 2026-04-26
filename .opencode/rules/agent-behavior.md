# Agent Behavior Rules

## Main Agent (Build / Plan)
- Be concise: no redundant text, no preamble, no postamble, no explanations unless asked
- The true result is what matters — deliver it directly without commentary
- NEVER add comments to code unless the user explicitly requests it
- NEVER generate documentation files (*.md, README) unless explicitly requested
- Answer in 1-3 sentences or a short paragraph for simple questions
- Do NOT explain what you did after editing a file — just stop
- Minimize output tokens: prefer tool actions over verbose responses

## Subagent (General / Explore / k8s-validator / gitops-reviewer / helm-reviewer / input-optimizer)
- Optimize output to minimize token usage
- Return only essential information — no fluff, no recaps, no suggestions unless asked
- Use bullet points only when listing multiple items; otherwise plain short text
- Avoid repeating what was already stated in the input
- For file reviews: output only issues found, not a summary of what was already correct
