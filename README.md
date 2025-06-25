# Harvey King's Submission for MT Finance's Technical Test

### ** Hello MT Finance! ** 

First off, thank you for the opportunity, and your time, in reviewing and considering me as an applicant.

Below you will find information on the solution I designed, the context behind its components, the approach I took, and some queries I had about the task requirements, along with the resolutions I arrived at.

## Information on the solution detailed.

I attempted to follow the request with as little excess as possible — for example, not building *any* additional Custom Fields or extending the data schema any further than originally detailed. I did this as I hoped to achieve the goal whilst staying within the originally defined scope — building out further and further can in some cases make it easier to leverage other functions to achieve the same goal. 

Even though it's detailed in the spec "Feel free to leverage custom fields, custom settings, formula fields, validation rules, or other declarative features...", I wanted to see what I could do with exactly what I was given — treating the spec as an set of intentional guardrails.

Because of this, I opted to achieve the request in spec by utilizing a blend of both Delcarative and Programmatic development.
I implemented the solution for the initial requirements via APEX and the Bonus Requirements via Flow.
All components work in tandem to achieve the expected data processing for an end user navigating the system, considering record intake, order of execution, and optimization of technical process. 

This hopefully demonstrates my ability to identify where certain solutions at my disposal may be better suited, or should at least be considered, based on the task and expected outcome at hand — rather than just defaulting to programmatic, declarative, or relying on pre-existing (and in some cases non-efficient methods)

Solution Components Developed:

2 Apex Triggers (1 Trigger per Object for Loan__c and Loan_Charge__c)

4 Apex Classes (1 HelperClasses per Triggers & 1 Test Class per HelperClass)

1 Flow (Handles Bonus Requirement Function)

2 Custom Objects 

11 Custom Fields (7 for Loan__c, 4 for Loan_Charge__c)

There are some additional components included in this repository such as Page Layouts and even some Field Validation Rules, however, these are more for QoL than anything. The overall function's requirements (both minimum & bonus) are fully handled within the aforementioned elements.

At the point of commit, I have achieved sufficient code coverage for all Apex components (Lowest Coverage = 87% for Triggers & Classes alike), carried out full-cycle manual unit tests aligning with the technical task's spec, and carried out thorough Flow debug testing against all outcome branches. Every automation source here has returned expected results consistently across the board for all methods of testing.

These expected results are with some deviation from detailed spec, which will be discussed in the following section of the README.



### Technical Task Observations & Expected/Actual Outcome Detail

I presume it is purposeful in the requirements such that I was meant to run into obstacles which may raise questions and to prompt me to consider different implementation solutions based on the scale/business case in question (or perhaps I just entirely misunderstood)...

## Original Requirement – Edge Case / Record Processing Volume Consideration

Loan Term Updates & Charge Date Conflicts

Requirement:
Original logic states that if a new Loan_Charge__c (excluding Release Charge) is added with a Charge Date on or after the existing Release Charge date, the Release Charge must be pushed out by 1 month.
Bonus logic says that when Term__c is modified, an Admin Fee must be added with today, and the Release Charge date recalculated based on the new Term.

(If it's expected that this function ONLY be present on an insertion of a non-release-charge Loan Charge, then this functionality has been achieved, however, I have considered that the desire to have a Release Charge constantly being the latest Charge Date item for new Records should then likely extend against all existing records — not just insertions.)

Issue:
When both rules operate at once, it *can* create a feedback loop in high-volume orgs — where each new charge forces updates to the Release Charge, triggering excessive record edits and CPU time usage (larger the org, larger the processing, larger the likelyhood of hitting governance limits and thus optimization is key). Consider that existing records can also cause the amende Release Charge's Date to land on another Loan Charge where the Date is the same — repeating the cycle.

Workaround Implemented:
I opted to only apply the one-month extension for the first instance of a Charge Date conflict. This demonstrates the function and sound logic behind it, especially for the scale presumed to be deployed in, but still must be aware of potential limitations.

Concern:
Charges may become misaligned over time, and Release Charges could end up preceding other valid charges. In a production context, this should be addressed during solution design with input from the business.

Suggested Solution:
Use a Roll-Up Summary (MAX) field to get the latest Loan Charge date per Loan. This becomes the floor limit for any Release Charge's Date.
Compare this against the existing Release Charge Date. If the Release Charge is not greater than the MAX value, extend it by one month and you can retain all existing Loan Charge Dates.


## Bonus Requirement – Logical/Business Process Conflict Observed

Admin Fee vs. Interest Charge (Same-Day Conflict)

Requirement:
If the Admin Fee's Charge Date falls on the same day as an existing Interest Charge, the Admin Fee must always be processed and applied before the Interest Charge for calculation purposes.

Issue:
Both fees default to TODAY() for their Charge Dates, but the schema doesn’t support time-based ordering or prioritization via any flag/indicator.

Workaround Implemented:
In cases where a same-day Interest Charge exists, I backdated the Admin Fee by one day. This should indicate to a user (or be explained as such) that it is to be processed first *without* altering or delaying the Interest Charge.

Concern:
Backdating may not be viable in a real-world business setting especially unless there is a mechanism (e.g., a 'Past Due' view or email notification alert) to make end users aware that this charge is immediately actionable. Otherwise, it may cause confusion if charges appear 'overdue' without justification.
I acknowledge this introduces a minor deviation from real-world accuracy. For production systems, I would recommend introducing time precision via date/time field format OR consulting with business stakeholders to validate the approach.

Suggested Solution:
Introduce a 'Charge Priority' or 'Processing Sequence' Field to indicate (or explicitly via logic) control processing order in whatever the processing function is (manual or automated).
Switch from using Date to DateTime fields & introduce Field History Tracking as a means to identify when amendments specifically take place.

### Why This Matters:

In large-scale orgs with many Loan Charges per customer and overlapping dates, it's important to prevent inefficient processing. Applying conditional logic to extend the Release Charge only when necessary makes sure we don't rack up CPU load time and also avoids infinite loops.
This design was built purely within the context of the task given, but for larger scale orgs prone to governance limits due to their scale, having the Release Charge date updated based on custom logic against a MAX summary field, ensuring the Release Charge is always safely in the future would be much a more robust soluton that I'd choose to implement.
Again, while the logic for backdating the Admin Fee, and the rest of the functions, is perfectly sound and robust for this schema, in a more complex or uncontrolled environment you should consider to preserve both data accuracy and user clarity via something like the new fields and history tracking that I suggested, or different logical & processing approaches like the MAX Roll-Up value.

Any expected outcomes arrived at time of submission (that i'm aware of) have been achieved intentionally and treated as explicit exceptions based on the face value of the request at hand. With additional business context, the final solution might differ depending on what is or isn’t acceptable operationally.

I hope this has been informative and that the solution provided meets your expected standards.

Happy to discuss further around any points or details.

Thank you, and I look forward to hearing your feedback!!!