# Scratch notes

## Deriving LaPerBa Variance

$$
\bar{BA} = \frac{1}{n}\sum{BA_i} \\
LAPERBA = \frac{GA \times LAI}{\bar{BA}} \\ 
Var[LAPERBA] = GA^2 \times Var[\frac{LAI}{\bar{BA}}]
$$

Per https://stats.stackexchange.com/questions/32659/variance-of-x-y, estimating $Var[LAI]$ from its stderr provided by Blasini.

$$
\begin{align*}
Var[LAPERBA] &\approx GA^2 \cdot \left(
\frac{SE_{LAI}^2 \cdot n}{\mu_{\bar{BA}}^2}
+ \frac{\mu_{LAI}^2}{\mu_{\bar{BA}}^4} \cdot Var[\bar{BA}]
\right)
\end{align*}
$$

$$
STDERR[LAPERBA] = \sqrt{\frac{VAR[LAPERBA]}{n}}
$$

## Deriving kmaxTree per BA Variance

$$
KMAX_{BA} = KMAX_{LA} \times LAPERGA \\
Var[KMAX_{BA}] = Var[KMAX_{LA} \times LAPERGA] \\
$$

If we assume independence, then $Var[XY] = Var[X]Var[Y] + Var[X]E[Y]^2 + Var[Y]E[X]^2$.

$$
Var[KMAX_{BA}] = \\
Var[KMAX_{LA}]Var[LAPERGA] + Var[KMAX_{LA}]E[LAPERGA]^2 + Var[LAPERGA]E[KMAX_{LA}]^2
$$