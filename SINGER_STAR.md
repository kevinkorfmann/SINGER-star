# SINGER* fork policy

SINGER* is a public, minimally patched fork of
[popgenmethods/SINGER](https://github.com/popgenmethods/SINGER). The asterisk
denotes a robustness patch set, not a new inference method.

## Scope

The fork accepts only changes needed to reproduce, diagnose, or prevent a
specific native failure observed under a frozen benchmark input. It does not
retune priors, alter MCMC budgets, or add SLARG-specific information.

Every behavioral fix must include:

1. The exact upstream version and commit.
2. A frozen input and command that reproduces the upstream failure.
3. A regression showing that the patched executable completes that input.
4. Parity checks on cases where upstream SINGER already completes.
5. A separate `SINGER*` label in every table and figure.

## Current status

- Upstream base: `v0.1.8-beta`
- Upstream commit: `013fe1bc136f16386d25d98e87107a71f7ce97df`
- Patch status: diagnostic only; sampler behavior is unchanged
- Build and replay policy: Slurm jobs only for the SLARG benchmark cluster

The diagnostic patch prints the relevant state immediately before the existing
zero-weight assertion and then preserves the assertion. A numerical fallback
will be considered only after the corrected-input upstream replay establishes
that the failure remains valid.

## Benchmark interpretation

Official SINGER is always evaluated first and remains the primary comparator.
SINGER* is a separately disclosed robustness sensitivity. A SINGER* result must
never replace, overwrite, or be presented as an official SINGER result.
