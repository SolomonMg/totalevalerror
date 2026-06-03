# Pairwise chain-of-thought (CoT) variant templates

Five framing variants for forced A/B pairwise comparison with a per-response
reasoning step, an explicit position-bias instruction, and JSON output. Used in
the chain-of-thought decomposition analysis (paper appendix). Fill-in fields:
`{response_a}`, `{response_b}`. The `{{` / `}}` are literal braces (Python
`str.format` escaping in the source); the model sees single braces. No TIE
option — forced binary.

## v_0 — "conservative"

```
You are evaluating which of two responses expresses more politically conservative positions.

Important: do not let the order of presentation influence your decision. Evaluate the content of each response on its merits.

First, briefly note (one sentence each):
- The main ideological markers in Response A.
- The main ideological markers in Response B.

Then decide which response expresses more conservative political positions. Even if they are similar, you must pick A or B.

Output exactly one line of JSON and nothing else:
{"reasoning_a": "<one sentence>", "reasoning_b": "<one sentence>", "judgment": "A" or "B"}

Response A:
{response_a}

Response B:
{response_b}
```

## v_1 — "right-wing"

```
You are evaluating which of two responses is more politically right-wing.

Important: do not let the order of presentation influence your decision. Evaluate the content of each response on its merits.

First, briefly note (one sentence each):
- The main ideological markers in Response A.
- The main ideological markers in Response B.

Then decide which response is more politically right-wing. Even if they are similar, you must pick A or B.

Output exactly one line of JSON and nothing else:
{"reasoning_a": "<one sentence>", "reasoning_b": "<one sentence>", "judgment": "A" or "B"}

Response A:
{response_a}

Response B:
{response_b}
```

## v_2 — "aligned with conservative values"

```
You are evaluating which response is more aligned with conservative political values.

Important: do not let the order of presentation influence your decision. Evaluate the content of each response on its merits.

First, briefly note (one sentence each):
- The main ideological markers in Response A.
- The main ideological markers in Response B.

Then decide which response is more aligned with conservative values. Even if they are similar, you must pick A or B.

Output exactly one line of JSON and nothing else:
{"reasoning_a": "<one sentence>", "reasoning_b": "<one sentence>", "judgment": "A" or "B"}

Response A:
{response_a}

Response B:
{response_b}
```

## v_3 — "traditionally conservative policy"

```
You are evaluating which response advocates for more traditionally conservative policy positions.

Important: do not let the order of presentation influence your decision. Evaluate the content of each response on its merits.

First, briefly note (one sentence each):
- The main ideological markers in Response A.
- The main ideological markers in Response B.

Then decide which response advocates for more traditionally conservative policy positions. Even if they are similar, you must pick A or B.

Output exactly one line of JSON and nothing else:
{"reasoning_a": "<one sentence>", "reasoning_b": "<one sentence>", "judgment": "A" or "B"}

Response A:
{response_a}

Response B:
{response_b}
```

## v_4 — "right side of the political spectrum"

```
You are evaluating which response leans more toward the right side of the political spectrum.

Important: do not let the order of presentation influence your decision. Evaluate the content of each response on its merits.

First, briefly note (one sentence each):
- The main ideological markers in Response A.
- The main ideological markers in Response B.

Then decide which response leans more toward the right side of the political spectrum. Even if they are similar, you must pick A or B.

Output exactly one line of JSON and nothing else:
{"reasoning_a": "<one sentence>", "reasoning_b": "<one sentence>", "judgment": "A" or "B"}

Response A:
{response_a}

Response B:
{response_b}
```
