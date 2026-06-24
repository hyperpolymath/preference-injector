<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Maintainers & Governance

## Tri-Perimeter Contribution Framework (TPCF)

This project uses a **graduated trust model** with three perimeters to balance security, collaboration, and emotional safety.

## Current Maintainers

### Perimeter 1: Core Maintainers (Maximum 5)

| Name | GitHub | Role | Since | Specialization |
|------|--------|------|-------|----------------|
| *TBD* | @maintainer1 | Lead Maintainer | 2024-01 | Architecture, Security |
| *TBD* | @maintainer2 | Release Manager | 2024-01 | CI/CD, Distribution |
| *Open* | - | Crypto Lead | - | Post-Quantum Crypto |
| *Open* | - | Community Lead | - | Code of Conduct, TPCF |
| *Open* | - | Documentation Lead | - | Guides, Examples |

**Responsibilities**:
- ✅ Merge to `main` branch
- ✅ Cut releases and publish to package registries
- ✅ Security vulnerability triage and patching
- ✅ TPCF perimeter promotion decisions
- ✅ Code of Conduct enforcement
- ✅ Strategic roadmap and architecture decisions

**Election Process**:
- Nominated by existing Perimeter 1 or self-nomination
- 2/3 majority vote by existing Perimeter 1 maintainers
- 6-month minimum contribution history
- Demonstrated technical excellence and community values alignment

**Term Limits**:
- No term limits, but annual re-confirmation vote
- Voluntary step-down encouraged if inactive >3 months
- Removed by unanimous vote of other Perimeter 1 members (serious violations only)

---

### Perimeter 2: Trusted Contributors (Unlimited)

| Name | GitHub | Contributions | Promoted | Specialization |
|------|--------|---------------|----------|----------------|
| *Open* | - | - | - | - |

**Access**:
- ✅ Direct commits to feature branches (not `main`)
- ✅ Triage and label issues
- ✅ Review and approve PRs from Perimeter 3
- ✅ Participate in architecture discussions
- ❌ Cannot merge to `main` without Perimeter 1 approval

**Promotion Criteria**:
- 3+ merged pull requests
- 30+ days of active contribution
- Demonstrated understanding of project values and architecture
- Zero Code of Conduct violations
- Automated promotion (no vote required)

**Demotion**:
- Automatic after 90 days of inactivity (can be re-promoted easily)
- Code of Conduct violations (temporary or permanent)

---

### Perimeter 3: Community Sandbox (Everyone)

**Access**:
- ✅ Fork and clone repository
- ✅ Open issues and discussions
- ✅ Submit pull requests
- ✅ Review others' PRs (feedback welcome!)
- ❌ Cannot commit directly to any branch

**This is YOU!** Start here, experiment freely, break things safely.

**No barriers to entry**: If you can create a GitHub account, you're in Perimeter 3.

---

## Governance Model

### Decision-Making Process

1. **Consensus First**: Aim for agreement, not voting
2. **Lazy Consensus**: Silence = agreement after 72 hours
3. **Voting**: When consensus fails, simple majority of Perimeter 1
4. **Veto Power**: Any Perimeter 1 can veto security/legal concerns (must provide alternative)

### Decision Types

| Decision Type | Who Decides | Process |
|---------------|-------------|---------|
| Bug fixes | Any contributor | Submit PR, get review |
| Small features | Perimeter 2+ | PR review, lazy consensus |
| Breaking changes | Perimeter 1 | Formal proposal, vote |
| Security issues | Perimeter 1 | Private triage, emergency powers |
| Code of Conduct | Perimeter 1 | Investigation, enforcement |
| Roadmap | Perimeter 1 | Community input, consensus |

### Emergency Powers

In case of:
- **Security breach**: Any Perimeter 1 can immediately revert commits
- **Legal threat**: Any Perimeter 1 can temporarily disable features
- **Harassment**: Any Perimeter 1 can immediately ban users

Post-emergency review required within 7 days.

---

## Conflict Resolution

### Technical Disagreements

1. **Discussion**: Open GitHub discussion, invite community input
2. **Prototyping**: Build competing implementations, compare objectively
3. **Mediation**: Third-party Perimeter 1 member arbitrates
4. **Vote**: If still deadlocked, simple majority of Perimeter 1

### Interpersonal Conflicts

1. **Private resolution**: Attempt 1-on-1 discussion first
2. **Mediation**: Code of Conduct team facilitates
3. **Enforcement**: Follow CODE_OF_CONDUCT.md escalation ladder

---

## Communication Channels

### Public Channels

- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: Q&A, ideas, polls
- **Pull Requests**: Code review, technical discussion

### Private Channels (Perimeter 1 Only)

- **Email**: maintainers@example.com (security, legal, conduct)
- **Monthly Sync**: First Monday of each month, 1 hour video call

### Community Channels (All Welcome)

- **Discord**: https://discord.gg/... (coming soon)
- **Matrix**: #preference-injector:matrix.org (coming soon)
- **Forum**: https://forum.example.com (planned)

---

## Responsibilities by Perimeter

### All Perimeters

- ✅ Follow CODE_OF_CONDUCT.md
- ✅ Respect others' time and expertise
- ✅ Assume good faith
- ✅ Give credit where due
- ✅ Prioritize emotional safety

### Perimeter 3 (Community)

- ✅ Read documentation before asking questions
- ✅ Provide reproduction steps for bug reports
- ✅ Be patient with review timelines
- ✅ Accept that not all ideas will be accepted

### Perimeter 2 (Trusted Contributors)

- ✅ Review PRs from Perimeter 3 within 7 days
- ✅ Mentor new contributors
- ✅ Write high-quality commit messages
- ✅ Keep feature branches up-to-date with `main`

### Perimeter 1 (Core Maintainers)

- ✅ Review security reports within 48 hours
- ✅ Cut releases on schedule (monthly or as-needed)
- ✅ Maintain CHANGELOG.md and SECURITY.md
- ✅ Enforce Code of Conduct fairly
- ✅ Respond to community concerns within 7 days

---

## Becoming a Maintainer

### Path to Perimeter 1

1. **Start**: Join Perimeter 3, make first PR
2. **Grow**: Earn Perimeter 2 through consistent contributions (30+ days)
3. **Lead**: Demonstrate leadership in area of expertise
4. **Nominate**: Self-nominate or be nominated by existing Perimeter 1
5. **Review**: Existing Perimeter 1 discusses candidacy (private)
6. **Vote**: 2/3 majority required
7. **Onboard**: 30-day probationary period with mentor

### What We Look For

- **Technical skills**: Proven ability to write quality code
- **Communication**: Clear writing, empathetic feedback
- **Community values**: Alignment with emotional safety and inclusion
- **Reliability**: Consistent contributions over time
- **Leadership**: Helping others, improving processes
- **Judgment**: Making sound decisions under uncertainty

### Red Flags (Automatic Disqualification)

- ❌ Code of Conduct violations
- ❌ Security negligence (e.g., committing secrets)
- ❌ Plagiarism or copyright violations
- ❌ Hostile or dismissive behavior toward contributors
- ❌ Attempt to bypass perimeter access controls

---

## Emeritus Status

Maintainers who step down from active duty are honored as **Emeritus Maintainers**:

- 🏅 Listed in MAINTAINERS.md with emeritus status
- 🎖️ Retains Perimeter 2 access (can be revoked if abused)
- 🙏 Welcomed back to Perimeter 1 if circumstances change (simplified process)

### Current Emeritus Maintainers

*None yet - this is a new project!*

---

## Amendment Process

This governance document can be amended by:

1. **Proposal**: Any Perimeter 2+ can propose changes via PR
2. **Discussion**: Minimum 14-day public comment period
3. **Vote**: 2/3 majority of Perimeter 1 required
4. **Announcement**: Changes announced in CHANGELOG.md

---

## Contact

- **Maintainer Email**: maintainers@example.com
- **Code of Conduct**: conduct@example.com
- **Security**: security@example.com

---

**Last Updated**: 2024-01-15
**Version**: 2.0 (TPCF Implementation)
**Next Review**: Every 6 months or as-needed
