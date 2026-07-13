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
- Patch status: minimal numerical recovery implemented; cluster validation pending
- Build and replay policy: Slurm jobs only for the SLARG benchmark cluster

The corrected 32-haplotype, 1 Mb frozen input failed in all four official
SINGER chains. Three chains reached the `mut_emit` zero-weight assertion and
one reached the terminal `sample_source_interval` failure. The input VCF has
SHA-256 `ad6307b1e0030803baf65185afcd59dc2b42c301ff7239246e52bbcf5bd55784`.

SINGER* keeps the upstream arithmetic unchanged whenever the emission weights
are finite and normalize to a positive value. Only an invalid normalization
enters a log-domain recovery using the same epsilon floor. If pruning has
collapsed the entire prior, recovery is restricted to states that have a valid
traceback path and uses their emission likelihoods. Source-interval sampling
similarly keeps the original path for valid weights, falls back first to the
corresponding forward probabilities and then to a uniform distribution over
structurally valid source links, and assigns a positive terminal residual to
the last supported state when floating-point roundoff prevents the cumulative
sum from crossing zero. Every recovery emits a `SINGER_STAR_RECOVERY` record
on standard error.

The Slurm validation graph in `slarg_cluster/` requires both exact scientific
output parity on a recovery-free run and completion of four bounded replays
using the failure seeds. Validation is fail-closed and writes a final seal only
after every check passes.

## Benchmark interpretation

Official SINGER is always evaluated first and remains the primary comparator.
SINGER* is a separately disclosed robustness sensitivity. A SINGER* result must
never replace, overwrite, or be presented as an official SINGER result.
