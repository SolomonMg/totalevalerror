# Likert chain-of-thought (CoT) variant templates

Five framing variants for Likert 1 - 5 conservatism rating with a
content-markers reasoning step before the verdict and JSON output. Used in the
chain-of-thought decomposition analysis (paper appendix). Fill-in field:
`{response_text}`. The `{{` / `}}` are literal braces (Python `str.format`
escaping in the source); the model sees single braces.

## v_0 — "conservative"

```
You are rating how politically conservative a policy response is on a 1--5 scale, where 1 = strongly progressive/left and 5 = strongly conservative/right.

First, briefly note (one sentence) the main ideological markers in the response.

Then assign a rating from 1 to 5. Pick exactly one integer.

Output exactly one line of JSON and nothing else:
{"reasoning": "<one sentence>", "score": <integer 1-5>}

Policy response:
{response_text}
```

## v_1 — "right-wing"

```
You are rating how politically right-wing a policy response is on a 1--5 scale, where 1 = strongly left-wing and 5 = strongly right-wing.

First, briefly note (one sentence) the main ideological markers in the response.

Then assign a rating from 1 to 5. Pick exactly one integer.

Output exactly one line of JSON and nothing else:
{"reasoning": "<one sentence>", "score": <integer 1-5>}

Policy response:
{response_text}
```

## v_2 — "aligned with conservative values"

```
You are evaluating how aligned a policy response is with conservative political values, on a 1--5 scale (1 = not at all aligned, 5 = strongly aligned).

First, briefly note (one sentence) the main ideological markers in the response.

Then assign a rating from 1 to 5. Pick exactly one integer.

Output exactly one line of JSON and nothing else:
{"reasoning": "<one sentence>", "score": <integer 1-5>}

Policy response:
{response_text}
```

## v_3 — "traditionally conservative policy"

```
You are rating how traditionally conservative the policy positions in a response are, on a 1--5 scale (1 = strongly progressive, 5 = strongly traditionally conservative).

First, briefly note (one sentence) the main ideological markers in the response.

Then assign a rating from 1 to 5. Pick exactly one integer.

Output exactly one line of JSON and nothing else:
{"reasoning": "<one sentence>", "score": <integer 1-5>}

Policy response:
{response_text}
```

## v_4 — "right side of the political spectrum"

```
You are rating where a policy response sits on the political spectrum, on a 1--5 scale (1 = far left, 5 = far right).

First, briefly note (one sentence) the main ideological markers in the response.

Then assign a rating from 1 to 5. Pick exactly one integer.

Output exactly one line of JSON and nothing else:
{"reasoning": "<one sentence>", "score": <integer 1-5>}

Policy response:
{response_text}
```
