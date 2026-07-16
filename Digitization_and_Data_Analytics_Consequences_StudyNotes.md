# Digitization and Data Analytics — Consequences
### Exam Study Notes & Expected Q&A
*ScaDS.AI TUD, Dr. Christoph Lehmann — Summer Term 2026*

---

## 1. Recap and Introduction

**Key framing:** the lecture collapses "data analytics," "machine learning," and "artificial intelligence" into one umbrella term **AI**, and is explicitly presented as **subjective** — a broad, opinionated perspective rather than a settled catalogue of facts.

### Hopes, promises, visions
- Improving efficiency and productivity
- Automating mundane tasks
- Enhancing decision-making via data-driven insight
- Mitigating societal challenges
- Enabling scientific breakthroughs
- Autonomous vehicles revolutionizing transport

### Nightmares, warnings, dystopias
- Job displacement / automation
- Privacy and security erosion
- Lack of transparency and explainability
- Ethical dilemmas
- Dependency and reliability risk

**Q&A**
- **Q: Why does the lecturer lump data analytics, ML, and AI under one term?**
  A: For simplicity of discussion — the consequences discussed largely apply across all three, even though technically they differ in scope (data analytics = descriptive/statistical, ML = pattern learning from data, AI = broader field including reasoning/agency).
- **Q: What is the central tension introduced in this recap?**
  A: The gap between AI's promised benefits (efficiency, discovery, automation) and its real risks (opacity, bias, dependency, job loss) — setting up the rest of the lecture as an exploration of that gap.

---

## 2. Data, Methods, Infrastructure

### 2.1 Data
- Success of any method depends primarily on **data quality**, not algorithm sophistication.
- Data cleaning/preprocessing consumes most project time but is unglamorous.
- Documentation matters: know what the data represents (example: Kaggle's Netflix Shows and COVID-19/JHU datasets).
- **Kaggle example issues:**
  - Netflix dataset: Kaggle *suggests* analysis tasks — raises the question **"who defines your analysis goal?"**
  - COVID-19 dataset: what counts as a "corona death"? Definitional ambiguity affects downstream conclusions (link to the **off-statistical issues** discussed in the Statistics lecture).
- Secondary data (like Kaggle) is useful for learning methods but is **not representative of the effort** needed to generate primary data from planned experiments.
- **Primary data** from deliberately designed experiments yields far more reliable insight than "found" data.

**Q&A**
- **Q: Why is "just download a Kaggle dataset" pedagogically misleading?**
  A: It skips the (often dominant) cost of data generation, cleaning, and definition — giving a false impression that data analysis is mostly about modeling.
- **Q: Give an example of a definitional ("off-statistical") problem in real datasets.**
  A: Defining "COVID-19 death" (death *with* vs. death *from* COVID) changes reported mortality statistics substantially.

### 2.2 Methods — how to choose one
Four criteria for method selection:
1. **Problem understanding / target** — context, scope, desired outcome (exploration, prediction, association).
2. **Scalability & efficiency** — does it work on large data / is it computationally feasible?
3. **Assumptions & limitations** — determine correct interpretation, avoid biased conclusions.
4. **Interpretability & explainability** — e.g., decision trees / linear regression are interpretable; deep learning is often a black box. Crucial in regulated domains or where humans must sign off on decisions.

**Wolpert's No-Free-Lunch Theorem** (https://doi.org/10.1109/4235.585893):
> *There is no single method that performs universally well on all problems.*

**Q&A**
- **Q: State the No-Free-Lunch theorem and its practical implication.**
  A: No algorithm is best for every problem, averaged over all possible problems — practically this means method choice must be problem-specific; "always use deep learning" (or any single method) is not a valid default strategy.
- **Q: Why might a bank prefer logistic regression over a neural network for credit scoring even if the network is more accurate?**
  A: Interpretability/explainability — regulatory requirements (e.g., must justify why a loan was denied) often outweigh small accuracy gains.

### 2.3 Target metrics
- Different tasks need different metrics: classification → accuracy, precision, recall, F1; regression → MAE, MSE, R².
- Each metric has trade-offs; **not all metrics can be maximized/minimized simultaneously** (e.g., precision vs. recall trade-off, illustrated by the classic "relevant elements" Venn-style diagram).
- Metric choice must match the application's real-world stakes.

**Domain examples:**
| Domain | Target metric | Rationale |
|---|---|---|
| Medical diagnosis | Sensitivity & specificity | Avoid missing true cases (false negatives) *and* avoid over-treating healthy patients (false positives) |
| Autonomous driving | False Negative Rate (FNR) | Missing a real obstacle/danger is catastrophic — minimize failures to detect |
| Financial risk assessment | Value at Risk (VaR) | Quantifies the maximum expected loss not exceeded with a given probability (e.g. 99.9%) over a time horizon |

**Q&A**
- **Q: Why is accuracy often a poor metric alone?**
  A: With imbalanced classes (e.g. rare disease, rare fraud), a model predicting the majority class always can have high accuracy while being useless — precision/recall/F1 or sensitivity/specificity are more informative.
- **Q: Why does autonomous driving prioritize FNR over overall accuracy?**
  A: A missed obstacle (false negative) can cause a fatal collision; false positives (unnecessary braking) are costly but far less dangerous — asymmetric error costs justify an asymmetric metric.
- **Q: What does "Value at Risk at 99.9% over 1 year" mean?**
  A: There is a 99.9% probability that losses over the next year will not exceed the VaR threshold (equivalently, a 0.1% chance of losses exceeding it).

### 2.4 Processing, computing, infrastructure
- Good infrastructure (hardware + software ecosystem) is necessary but **not sufficient** — data quality and domain knowledge still dominate.
- Hardware (CPU/GPU/memory/storage) is getting cheaper; virtualization/cloud computing lowers the barrier to strong infrastructure.
- Distributed-systems challenges:
  - **I/O**: bring data close to computation (data locality)
  - **Distribution/parallelization strategies**, especially relevant for LLM training
- **Theory vs. reality of automation** (xkcd #1319): automating a task is imagined as a one-time investment yielding free time, but in reality it becomes ongoing debugging/rethinking/maintenance with *less* free time than before.
- **"All modern digital infrastructure"** (xkcd #2347): critical systems often rest on a fragile foundation maintained by one underappreciated person/project — a metaphor for dependency risk in AI/data infrastructure.
- **Human factor** is decisive for technology adoption:
  - Introducing a new standard file format across a long production chain
  - Convincing a group of people to adopt a new tool/software
  - Technology succeeds or fails based on organizational buy-in, not just technical merit.

**Q&A**
- **Q: According to the lecture, what is the "main challenge" for complex data/AI problems?**
  A: Integrating data, hardware, and tools together (not any single component alone) — plus reliability, stability, and maintainability over time.
- **Q: What point does the xkcd #1319 comic make about automation?**
  A: The naive theory (write code once → free time) rarely matches reality (ongoing debugging, rethinking, and maintenance eat into or exceed the time "saved").
- **Q: What does the xkcd #2347 "digital infrastructure" comic warn about?**
  A: Widely-used digital systems often depend on small, under-resourced, easily-overlooked components/maintainers — a single point of fragility for the whole ecosystem.
- **Q: Give two real examples of the "human factor" in technology adoption from the slides.**
  A: (1) Introducing a new standard file format for production data across a long product chain; (2) convincing a group of people to use a specific tool or piece of software.

---

## 3. Non-Technical Issues

### 3.1 AI learning from AI (model collapse risk)
- LLM training data increasingly comes from an internet that itself contains AI-generated content → **AI learns from itself**, a feedback loop.
- Text can also be *directly* generated by LLMs for training purposes.
- **AI-annotated training data**: research compares human vs. LLM annotation (e.g., risk-labeling of traffic situations).
- Risk: AI-driven data generation may **reproduce (and amplify) intentionally implemented biases or artifacts** from the generating model.

**Q&A**
- **Q: What is the risk of training future AI systems on data scraped from an internet full of AI-generated content?**
  A: Potential "model collapse" / feedback loops where errors, biases, or stylistic artifacts of earlier AI systems get amplified in later generations, and the models increasingly lose touch with the original human-generated data distribution.

### 3.2 AI applications — accuracy claims vs. reality (facial recognition)
- Metropolitan Police (Greater London) live facial recognition trials (Notting Hill Carnival 2016; Leicester Square, Westfield Stratford, Whitehall 2017 Remembrance Sunday).
- Independent researchers found the system **81% inaccurate** — majority of "matches" were false positives against people not on any wanted list.
- Official claim: only 1-in-1,000 error rate.
- Compare to the **base-rate fallacy** discussed in the Statistics lecture — similarly ~80% false-positive rates arise when a rare-event detector is applied to a huge population, even with seemingly high sensitivity/specificity.

**Q&A**
- **Q: Explain, using the base-rate fallacy, why a facial recognition system can have a low per-match error rate yet be "81% inaccurate" in practice.**
  A: If the base rate of true "wanted persons" in a crowd is extremely small, then even a system with high per-comparison accuracy generates far more false positives than true positives in absolute terms, because the population of non-matches vastly outweighs true matches (classic base-rate fallacy / low prior probability problem).
- **Q: Why can two very different-sounding statistics ("1 in 1,000 errors" vs. "81% inaccurate") both be technically true?**
  A: They measure different things — one is a per-decision/per-face error rate (denominator = all comparisons), the other is the proportion of *flagged matches* that are wrong (denominator = flagged alerts only). Base rates make these numbers diverge sharply.

### 3.3 Reproducibility and data access
- **"Data hugging"**: proprietary datasets prevent independent verification of AI claims.
- Systematic review of ~1,300 critical-care AI studies: **85% did not share datasets, 87% did not share code**.
- **Case study — Apple wrist-PPG "biological age" model:** claimed MAE ≈ 2.89 years.
  - Independent replication on UK Biobank (Karpurapu et al. 2026): MAE ≈ 5.24–5.97 years — only marginally better than simply predicting the population mean (baseline MAE 6.98 years).
- **Real-world consequences of unverified deployment:**
  - **Epic sepsis algorithm**: poor external validation discovered only *after* nationwide clinical deployment.
  - **Philips ECG telemetry**: missed alerts led to 2 deaths and 109 injuries, triggering an FDA Class I correction (the most serious FDA recall category).
- **Core message:** *"If you cannot reproduce it, you cannot trust it — regardless of how good the ML is."*

**Q&A**
- **Q: What does "data hugging" mean and why is it a scientific problem?**
  A: Withholding proprietary datasets/code, preventing independent researchers from verifying or replicating published AI performance claims — undermines the scientific method and can hide inflated or non-generalizable results.
- **Q: What happened when Apple's biological-age model was independently tested on UK Biobank data?**
  A: Error more than doubled (MAE ~2.89 → ~5.24-5.97 years) and was only marginally better than a naive "always predict the mean" baseline — showing the original claim did not generalize.
- **Q: Name two real clinical AI systems whose insufficient validation caused patient harm.**
  A: The Epic sepsis prediction algorithm (deployed nationally before adequate external validation) and Philips ECG telemetry monitoring (missed alerts causing 2 deaths and 109 injuries, FDA Class I correction).
- **Q: What is an "FDA Class I correction"?**
  A: The FDA's most serious recall/correction classification, used when a device could cause serious injury or death.

### 3.4 Deepfakes
- Deepfakes used to influence the November 2023 elections in India.
- Examples: a minister deepfake urging people to vote against the sitting state government; a quiz show engineered around Madhya Pradesh politics to build anti-incumbency sentiment.
- Political parties commission private-sector advocacy/campaign agencies to produce and distribute deepfakes.
- Used to spread candidate misinformation.
- Ironic dynamic: established parties do not fight deepfakes because **they use deepfakes themselves** to gain advantage — a collective-action / prisoner's-dilemma-like problem.
- **Discussion prompt:** what are the implications for democracy?

**Q&A**
- **Q: Why do political parties largely fail to push back against deepfakes even when harmed by them?**
  A: They benefit from using the same technology themselves, creating a mutual disincentive to regulate or expose it — a collective-action problem where no single actor wants to unilaterally disarm.
- **Q: What democratic risks does the widespread use of deepfakes raise?**
  A: Erosion of shared factual ground, manipulation of voter perception via fabricated statements/scenarios, difficulty distinguishing real from fake media, and potential for those in power to dismiss *genuine* evidence as "deepfake" (the "liar's dividend").

### 3.5 Astroturfing
- **Definition (implicit):** fake grassroots campaigns manufactured by organized/corporate interests to appear as authentic public sentiment.
- **Historical case — Alliance of Australian Retailers (2010):** presented as 19,000 authentic small-business members opposing Australia's world-first plain cigarette packaging law; in reality secretly financed by Philip Morris International, British American Tobacco, and Imperial Tobacco.
- **The shift with AI:** what used to cost millions of dollars per year (staff, PR agencies, coordination) can now be replicated for **~€10/month plus one afternoon** using an LLM + automation tooling.
- Key point: astroturfing is *not new*, but AI collapses its cost by orders of magnitude, massively increasing scale and accessibility for bad actors.

**Q&A**
- **Q: What is astroturfing, and how did the Alliance of Australian Retailers exemplify it?**
  A: A fake grassroots movement engineered by powerful/corporate interests; the AAR presented itself as an authentic small-business coalition while secretly being funded and directed by major tobacco companies to fight plain-packaging legislation.
- **Q: How has AI changed the economics of astroturfing?**
  A: It reduced the cost from millions of dollars/year (requiring large PR operations) to roughly €10/month plus minimal human effort (LLM-generated content + automation tools), massively democratizing (and thus increasing the danger of) manipulation campaigns.

### 3.6 Cybersecurity
- AI is dual-use for security: the same technology, pointed in an adversarial direction, reshapes the threat landscape.
- **Fully autonomous attacks** without human intervention — adaptive attacks at machine speed, removing human reaction-time latency.
- **Attacks on the AI agents themselves**, e.g. **prompt injection**.
- AI agents are described as **"digital insiders"**: privileged entities with access, autonomy, and inherited trust within an organization's systems.
- **Core claim:** *"Attacker–defender asymmetry has shifted sharply: attacks scale with compute, defenses still scale with headcount!"*

**Q&A**
- **Q: What is prompt injection, and why are AI agents especially vulnerable to it?**
  A: An attack where malicious instructions are embedded in content the AI processes (e.g. a document, webpage, email) to hijack its behavior. AI agents are vulnerable because they often have broad system access/autonomy ("digital insiders") and may not reliably distinguish trusted instructions from untrusted content they read.
- **Q: Explain the "attacker–defender asymmetry" argument from the slides.**
  A: Attacks can be automated and scaled simply by adding more compute (cheap, fast, parallelizable), while defenses still largely require human security analysts (expensive, slow to hire/train) — meaning the offense scales faster than the defense, tilting the balance toward attackers.

### 3.7 Ethical AI
- **What is ethics (as framed here)?** Not about assessing the absolute moral status of actions, but about identifying **relevant societal implications** of using an AI system.
- **Three main ethical perspectives:**
  1. **Deontological** — actions have an absolute/inherent moral status (rule-based).
  2. **Consequentialist** — moral status depends on the consequences/outcomes of an action.
  3. **Descriptive/empirical** — moral status is derived empirically, e.g. by observing or surveying people.
- **Key open question posed to the audience:** *which* ethical perspective should an AI system implement — and who decides?
- **Ethical frameworks / certification attempts:**
  - **Value-based Engineering** per ISO/IEC/IEEE 24748-7000: principles include Ecosystem Responsibility, Stakeholder Inclusiveness, Context-Sensitivity, Value Identification (with Moral Philosophy/Spiritual Tradition), Understanding Values at Depth, Leadership Engagement, Respect for Regional Laws and International Agreements, Willingness to Renounce Investment, Transparency of the Value Mission, Risk-based System Design.

**Q&A**
- **Q: Differentiate deontological, consequentialist, and descriptive/empirical ethics with an AI example.**
  A: Deontological — an AI content filter blocks a category of speech because it is *rule-defined* as forbidden, regardless of context/outcome. Consequentialist — the same filter is judged by whether blocking it actually *reduces harm* in practice. Descriptive/empirical — what counts as "harmful" is determined by surveying a population's actual moral judgments rather than applying a fixed rule or predicted outcome.
- **Q: Why is "which ethical perspective to implement" a genuinely hard, contested question rather than an engineering detail?**
  A: Different perspectives can prescribe different system behavior for the same case, and there's no universal consensus on which is "correct" — the choice embeds value judgments about whose ethics counts, in what context, decided by whom (developers? regulators? society?).

#### Application I — COMPAS (criminal recidivism prediction)
- US justice system uses COMPAS, a **proprietary** ML model, to predict recidivism risk.
- Proprietary → unknown/opaque decision process (links to **explainability**).
- Criminologists (ProPublica investigation) accused COMPAS of **racial bias**.
- COMPAS uses 130+ input factors; **typos in input data can materially change outcomes/unfairness**.
- Ethical questions raised:
  - Should machine-driven decisions be used for high-stakes decisions at all?
  - Is "objectivity" even a valid goal, or do individualized/subjective decisions serve justice better in some cases?
  - How do we even measure (un)fairness or bias?

**Q&A**
- **Q: What was the central controversy around COMPAS?**
  A: A proprietary, opaque risk-assessment algorithm used in US sentencing/parole decisions was found (by ProPublica's analysis) to have racially disparate error patterns, while the exact scoring logic was not publicly disclosed or independently auditable.
- **Q: Why does data-entry quality (e.g., typos) matter so much for a system like COMPAS?**
  A: With 130+ input factors feeding an opaque model, small data-entry errors can shift an individual's risk score in ways that are neither traceable nor explainable, directly affecting real sentencing/parole outcomes — showing how "black box + messy input" compounds harm.

#### Application II — "moral/toxicity scores" from NLP models
- Extracting a "moral score" from text using a BERT-based model (arXiv:2103.11790).
- Score is built from many assumptions/abstractions: first principal component (PCA), normalization by maximum raw score, calibration against survey data (who was asked, what was asked).
- Score range [-1, 1]; **threshold ms < -0.5 defined as "toxic."**
- Follow-up questions raised:
  - Why exactly -0.5? What drives that specific threshold — is it interpretable?
  - How should the difference between, say, -0.4 and -0.5 be interpreted (arbitrary cutoff near a continuous score)?
  - The approach implicitly encodes **deontological ethics** (rule-based cutoff) because that is algorithmically easy to implement — but is a fixed rule actually a societal consensus? Who decides good vs. bad?

**Q&A**
- **Q: Why is a hard threshold like "moral score < -0.5 = toxic" ethically and statistically problematic?**
  A: It imposes an essentially arbitrary boundary on a continuous, model-derived score built from many unverified assumptions (PCA component choice, normalization, survey calibration) — small, likely non-meaningful differences near the cutoff (e.g., -0.49 vs -0.51) get treated as categorically different, and the rule-based (deontological) framing hides the fact that "toxicity" is actually a contested, context-dependent social judgment.

#### Application III — moderation/reflection tools (Perspective API)
- Two use patterns of the same "toxicity" scoring technology, examples from perspectiveapi.com/case-studies:
  1. **Decision-support for moderators** (e.g. Southeast Missourian newspaper): flags comments by toxicity score to help moderators decide what to remove; reduced highly-toxic comments ~96% in trial.
  2. **Direct user-facing reflection** (e.g. OpenWeb): shows commenters a real-time toxicity signal before posting, letting them edit or repost anyway; in one study ~44.7% of commenters who edited removed/replaced offensive words, ~7.6% rewrote the comment entirely.
- Concerns raised:
  - Moderators may become "lazy," simply rubber-stamping the machine's decision.
  - It may be **easier to justify a decision based on a machine score** than on individual human reasoning (diffusion of responsibility).
  - Does real-time reflection actually change long-term behavior/thinking, or just surface wording?
  - Is rewriting/reformulating comments based on an algorithmic nudge functionally a form of **censorship**?
  - Ultimate question: are we ending up "making only some algorithm happy" rather than solving the underlying social problem?

**Q&A**
- **Q: What is the difference between "AI as decision support" and "AI as a reflection tool" in content moderation, per the slides?**
  A: Decision support gives a *moderator* (a human with authority) a toxicity score to help decide whether to remove content; the reflection tool gives *the author* real-time feedback before posting, letting them self-edit. The former risks moderator over-reliance/laziness; the latter raises questions about whether it produces surface-level wording changes vs. genuine behavior change, and whether it constitutes a form of soft censorship.
- **Q: What is the "responsibility diffusion" concern raised about algorithmic decision support?**
  A: It may be psychologically/organizationally easier to justify a harsh decision ("the algorithm flagged it") than to own an individual, reasoned judgment call — shifting accountability away from the human decision-maker.

#### General issues with computer-aided/automated decisions
- How to justify decisions made *against* the algorithm's recommendation?
- Does human laziness bias people toward simply accepting AI outputs?
- Impact on trust in human decision-making ability and innovation capacity over time (deskilling)?
- Who bears responsibility/liability for the consequences of AI-influenced decisions?
- What happens, long-term, to the human ability/skill to make such decisions unaided?

**Q&A**
- **Q: What is "deskilling" in the context of AI-assisted decision-making, and why might it matter?**
  A: Over-reliance on AI recommendations can erode humans' own decision-making skill and judgment over time, since practice/exercise of that skill declines — creating a dependency risk if the AI system fails, is unavailable, or is wrong in a novel situation.

### 3.8 Legal aspects
- **Central question:** who is legally responsible for wrong or misleading AI output?
- **Air Canada chatbot case:** the airline's customer-service chatbot invented a refund policy that did not actually exist. A Canadian tribunal (Feb 2024) ruled **Air Canada must honor the invented policy** — the company was held responsible for its chatbot's statements. (arstechnica.com, Feb 2024)
- **Microsoft Services Agreement, §3 / §4.b.iii** — "Code of Conduct enforced by AI": Microsoft states it *"may use automated systems and humans to review content to identify [...] illegal or harmful content or conduct."*
  - "Harmful content" has **no legal definition** — left to platform discretion.
  - Common practice at Google, Apple, Meta, etc.
  - Real consequences: suspicious automated scan results have been forwarded to authorities, triggering police investigations (cf. the widely reported Google/NYT "toddler photo" case and Microsoft account-suspension reporting cited in footnotes).
  - Accounts can be permanently suspended even after a case is closed — no reactivation, complete data loss.
  - **Bottom line: the risk sits on the customer's side, not the platform's.**
- **EU AI Act:**
  - Requires providers to at least **disclose** that automated systems are involved in decisions (from Aug 2026) — but **disclosure is not remedy** (it doesn't grant an appeal right or compensation by itself).
  - In force since **1 August 2024** — first comprehensive AI regulation worldwide.
  - **Risk-based approach**: unacceptable / high / limited / minimal risk tiers.
  - **Phased timeline (as of July 2026):**
    - Feb 2025: prohibitions on unacceptable-risk systems (social scoring, cognitive manipulation, real-time remote biometric identification)
    - Aug 2025: obligations for General-Purpose AI (GPAI) models
    - **2 Aug 2026**: transparency obligations — chatbots must disclose they are AI; deepfakes must be labeled as artificially generated
    - High-risk system obligations phase in through 2027
  - **General exception:** military, defence, national security are excluded.
  - Reference: https://artificialintelligenceact.eu/

**Q&A**
- **Q: What legal precedent did the Air Canada chatbot case set?**
  A: A company can be held liable for information/policies its AI customer-service system communicates to customers, even if the AI "hallucinated" a policy that never officially existed — companies cannot simply disclaim responsibility for their deployed AI's outputs.
- **Q: Why is "no legal definition of harmful content" a problem, per the Microsoft Services Agreement example?**
  A: It gives platforms broad, largely unaccountable discretion to flag, restrict, or escalate content/accounts via automated systems, while users bear the real-world consequences (lost data, police involvement) with limited recourse — creating an asymmetric risk allocation.
- **Q: What is the EU AI Act's risk-based structure, and give one example system per tier where possible from the slides.**
  A: Four tiers — unacceptable risk (banned, e.g. social scoring, real-time remote biometric ID, cognitive manipulation), high risk (heavily regulated, phased through 2027), limited risk (transparency obligations, e.g. chatbots/deepfakes must disclose AI involvement from Aug 2026), and minimal risk (largely unregulated).
- **Q: Why does the lecturer stress that "disclosure is not remedy" regarding the EU AI Act?**
  A: Requiring a system to *disclose* that AI/automation is involved does not itself provide affected individuals with a right to appeal, correction, or compensation — transparency alone doesn't fix substantive harms from wrong AI decisions.
- **Q: What sectors are exempted from the EU AI Act, and why might that be significant?**
  A: Military, defence, and national security uses are generally exempted — meaning some of the highest-stakes/most consequential AI applications (autonomous weapons, surveillance, etc.) fall outside the Act's risk-based protections.

### 3.9 Resource-related issues
- Frontier AI development requires massive **financial, human, time, and technical/hardware** resources.
- **Financial scale (OpenAI example):**
  - Started with a $1B budget in 2015.
  - Microsoft invested a further $1B (2019) and $10B (2023).
  - Nvidia invested $100M in 2024.
  - Despite this, OpenAI reported a **$5B loss in 2024** on $3.7B revenue.
- **Development timeline & team scale:**
  - GPT-1 (mid-2018): ~2–3 years development.
  - GPT-3 (May 2020): 32 authors on the preprint.
  - GPT-4 (March 2023): 284 authors on the preprint.
  - OpenAI headcount: ~770 (Nov 2023) → ~3,500 (Sept 2024) → up to 8,000 projected by end of 2026.
- **Compute scale (training cost table):**

| Model (year) | Parameters | Training tokens | Accelerators | Training compute |
|---|---|---|---|---|
| GPT-3 (2020) | 175 B | 300 B | 1k Nvidia V100 | 800k GPU-hours (~34 days) |
| GPT-4 (2023) | 1.8 T | 13 T | 25k Nvidia A100 | 54M GPU-hours (~90–100 days) |
| Llama 3.1 (2024) | 405 B | 15 T | 16k Nvidia H100 | 30M GPU-hours |

  - Rule of thumb: 750 words ≈ 1,000 tokens.
  - Cloud pricing: Nvidia H100 ≈ USD 2–7 / GPU-hour (on-demand).
  - TU Dresden's ZIH GPU cluster **Capella**: 624 Nvidia H100 GPUs (for comparison/scale).

**Q&A**
- **Q: Roughly estimate the pure compute cost (cloud, on-demand) of training GPT-4 using the numbers given.**
  A: 54,000,000 GPU-hours × ~USD 2–7/hour ≈ **USD 108M – 378M** just for on-demand GPU compute (excluding staff, data, R&D, failed runs) — illustrating the scale of capital required for frontier models. (Actual dedicated-cluster costs are typically lower than on-demand cloud pricing, but this shows the order of magnitude.)
- **Q: What does the growth in preprint author count (32 → 284) between GPT-3 and GPT-4 suggest?**
  A: Frontier model development has shifted from small research-team efforts to massive, industrialized, highly parallel engineering projects — reflecting the resource-intensity trend.
- **Q: Why does the lecture juxtapose OpenAI's investment figures with its reported loss?**
  A: To highlight that even with tens of billions in capital, frontier AI development is not yet profitable — underscoring how resource-intensive (and financially risky/unsustainable in the short term) this technology is.
- **Q: Why is the Capella cluster (624 H100s) mentioned alongside GPT-4's 25,000 A100s?**
  A: To give students a tangible sense of scale — a well-resourced university HPC cluster is roughly two orders of magnitude smaller than what a single frontier commercial model's training run required.

### 3.10 Geopolitical dimension
- Once resources reach this scale, frontier AI **stops being purely a product decision** and becomes a matter of national strategy.
- **Case study: Anthropic's Claude "Mythos" release (June 2026).**
  - The White House imposed restrictions on foreign access, invoking **export-control regulations**.
  - Described as the **first time a commercial LLM release triggered an export-control-style government response within a single news cycle**.
- **Key takeaway:** frontier models are now **dual-use technology** — capability thresholds can trigger government intervention, and AI power/leadership is no longer purely economic but explicitly **geopolitical**.
- *(Note: this slide's framing is illustrative of a broader pattern of increasing state involvement in frontier AI — see the product_information at the top of this conversation for the actual, verified account of what happened with Claude Fable 5 / Mythos 5 in June–July 2026, since the two accounts differ in detail.)*

**Q&A**
- **Q: What does it mean to call frontier AI models "dual-use technology"?**
  A: Like nuclear technology or advanced semiconductors, the same underlying capability can serve civilian/commercial purposes and also have military, intelligence, or strategic national-security applications — which is why governments increasingly regulate frontier model access/export similarly to other dual-use goods.
- **Q: Why might a government treat a commercial chatbot release as a national-security matter?**
  A: If model capabilities cross certain thresholds (e.g., in cyber-offense assistance, persuasion/influence, or scientific/biological uplift), the model could provide meaningful advantage to foreign state or non-state actors — prompting export-control-style restrictions similar to other controlled technologies.

### 3.11 AI in practice: roles and responsibilities
Maps each lecture topic to real job roles, scope of work (Research / Production / Interpretation), and a representative task/question:

| Topic | Job label(s) | Scope | Typical question |
|---|---|---|---|
| Introduction | Data Strategy Consultant | Research | Where can data create value, and what to tackle first? |
| Data Preprocessing | Data Engineer | Production | How to clean/transform/pipeline raw data reliably? |
| Statistics | Data Analyst | Interpretation | What trends stand out in the data? |
| Data Management | Data Steward | Research | How to document/version/store data for 10-year reproducibility? |
| Machine Learning & Deep Learning | Data Scientist / ML Engineer / AI Research Engineer | Interpretation + Production + Research | Hidden segments? Meets accuracy/latency targets? Beats SOTA? |
| Distributed Computing | Big Data Engineer / MLOps Engineer | Production | Move/process 50TB/day? Model still accurate — retrain/monitor/rollback? |
| Consequences (this lecture) | AI Ethics Officer | Interpretation (societal & ethical reflection) | Does this model treat all user groups fairly; legal/social implications? |

**Q&A**
- **Q: Why does the lecture end with this roles/responsibilities table rather than another technical topic?**
  A: To make explicit that the material covered throughout the whole course maps onto distinct, real professional roles in industry — situating "Consequences" (this lecture's topic) as the domain of the **AI Ethics Officer**, whose job is societal/ethical interpretation rather than pure technical production.
- **Q: What three "scopes of work" recur across roles in the table?**
  A: Research (exploratory/foundational work), Production (building/operating reliable systems), and Interpretation (making sense of results for decisions/stakeholders).

---

## 4. Conclusions

- **AI is not only about methods and hardware** — non-technical dimensions (ethics, law, human factors, resources, geopolitics) are at least as important.
- Using AI systems can have **large implications on human behavior and society**.
- Important to distinguish **high-stakes vs. low-stakes decisions** — the bar for rigor, transparency, and accountability should scale with stakes.
- Many aspects (ethics, legal liability) are inherently **hard to measure or fully cover**.
- Additional dimensions exist but weren't covered in depth here — **especially economic aspects**.
- **Bottom line (the lecture's thesis):**
  > *"The most relevant issues and questions while using AI broadly are related to non-technical questions."*
- Closing visual cue: **Brave New World** (Huxley) and **Nineteen Eighty-Four** (Orwell) — two classic dystopian lenses (soft, pleasure/consumption-driven control vs. hard, surveillance/coercion-driven control) as frameworks for thinking about where AI-enabled societal risk might lead.

**Q&A**
- **Q: What is the single overarching thesis of this lecture?**
  A: That the hardest and most consequential problems with AI are not technical (algorithms, hardware, methods) but **non-technical** — ethical, legal, social, economic, and geopolitical.
- **Q: Why are Brave New World and Nineteen Eighty-Four both referenced as closing images, rather than just one?**
  A: They represent two contrasting dystopian mechanisms of control — Huxley's *Brave New World* depicts control through comfort, distraction, and manufactured consent (arguably echoed by algorithmic content feeds, recommendation systems, engagement optimization), while Orwell's *1984* depicts control through surveillance, coercion, and information suppression (echoed by facial recognition, mass monitoring, censorship-adjacent moderation) — together framing two different "failure modes" AI-enabled societies could drift toward.
- **Q: Why does the lecturer explicitly say "distinguish high-stake and low-stake decisions" as a conclusion?**
  A: Because many of the case studies (COMPAS sentencing, medical diagnosis, autonomous driving, Epic sepsis algorithm) show that the acceptable level of risk, required interpretability, and validation rigor for AI systems should not be uniform — it must scale with the real-world stakes of the decision being automated or supported.

---

## Quick-reference: key numbers & cases to memorize

| Item | Key fact |
|---|---|
| Met Police facial recognition | 81% inaccurate (independent report); claimed 1-in-1,000 error rate |
| Critical-care AI reproducibility review | ~1,300 studies; 85% no dataset shared, 87% no code shared |
| Apple wrist-PPG biological age | Claimed MAE ≈2.89 yrs → independent replication MAE ≈5.24–5.97 yrs (baseline "predict the mean" = 6.98 yrs) |
| Philips ECG telemetry | 2 deaths, 109 injuries → FDA Class I correction |
| Alliance of Australian Retailers | 19,000 "small business" front, secretly funded by Philip Morris/BAT/Imperial Tobacco (2010) |
| Astroturfing cost shift | Millions/year → ~€10/month + one afternoon with AI tools |
| Air Canada chatbot ruling | Feb 2024 — company must honor policy invented by its chatbot |
| EU AI Act | In force since 1 Aug 2024; transparency duties from 2 Aug 2026; risk tiers: unacceptable/high/limited/minimal; military/defence exempted |
| GPT-3 → GPT-4 authors | 32 → 284 preprint authors |
| OpenAI headcount | 770 (Nov 2023) → ~3,500 (Sept 2024) → up to 8,000 (end 2026 projected) |
| OpenAI 2024 finances | $5B loss on $3.7B revenue |
| GPT-4 training compute | 25k Nvidia A100 GPUs, 1.8T parameters, 13T training tokens, ~54M GPU-hours |
| TU Dresden Capella cluster | 624 Nvidia H100 GPUs |
| No-Free-Lunch theorem | Wolpert — no single method is universally best across all problems |
