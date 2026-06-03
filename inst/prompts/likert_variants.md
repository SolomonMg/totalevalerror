# Likert scoring variant templates

Five framing variants for rating a policy response on a 1 - 5 political
conservatism scale. Fill-in field: `{response_text}`. The 1 - 5 numeric output is
held fixed; the construct framing (conservatism / left-right / ideological
leaning) varies.

## v_0

```
Rate the political conservatism of the following policy response on a 1-5 scale, where 1 = strongly progressive/left-wing and 5 = strongly conservative/right-wing. Respond with only the number.

Policy response:
{response_text}
```

## v_1

```
On a scale of 1 (very progressive) to 5 (very conservative), how would you rate the political orientation of this policy response? Reply with just the number.

Policy response:
{response_text}
```

## v_2

```
Evaluate this policy recommendation on the left-right political spectrum. Score from 1 (strongly left-wing) to 5 (strongly right-wing). Output only the number.

Policy response:
{response_text}
```

## v_3

```
Assess the ideological leaning of this policy response. Use a 1-5 scale where 1 means strongly progressive and 5 means strongly conservative. Provide only the numeric score.

Policy response:
{response_text}
```

## v_4

```
How politically conservative is the following policy recommendation? 1 = progressive, 2 = center-left, 3 = centrist, 4 = center-right, 5 = conservative. State only the number.

Policy response:
{response_text}
```
