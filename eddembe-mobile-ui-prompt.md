from pathlib import Path

content = """# Eddembe — Professional UI/UX Redesign Brief

## Role
Act as a senior product designer and experienced mobile UI engineer. Redesign the existing **Eddembe** app interface so it feels polished, trustworthy, modern, accessible, and ready for real users.

Use the uploaded screenshot as the starting point. The current screen asks **“What is happening?”** and offers four entry points:
- My landlord wants me out
- Problem at work
- Land dispute
- I need information from government

The bottom navigation contains **Home, Ask, Scan, and My cases**.

## Design direction
Use the best principles of:
- **Google Material 3**: clear hierarchy, accessible touch targets, purposeful color, expressive but restrained components, consistent spacing, and predictable navigation.
- **Microsoft Fluent Design**: clean layouts, subtle depth, refined surfaces, calm typography, and restrained use of visual effects.

Do not copy either system blindly. Create a cohesive design language that fits Eddembe's purpose: helping people understand practical legal and civic issues. It should feel safe, respectful, and easy to use—even for users with limited digital experience.

## Main objective
Transform the current screen from a dark, bulky list of cards into a **clean, contemporary, welcoming interface** with strong typography, balanced whitespace, refined category cards, and clear actions.

Keep the experience simple. Do not make it look like a flashy fintech dashboard, a gaming app, or a generic AI-generated landing page.

## Visual design requirements

### 1. Color system
- Keep green as the core brand color because it communicates trust and guidance.
- Use a refined palette with a light, warm or neutral background, dark readable text, subtle borders, and green accents.
- Use green for primary actions, selected navigation states, icons, and small highlights—not as a background for everything.
- Give each surface a clear purpose: page background, cards, selected states, and navigation should be visually distinguishable.
- Ensure sufficient contrast for text and icons.
- If the app already has established brand colors or theme tokens, inspect and reuse them where sensible rather than introducing a conflicting palette.
- Support dark mode only if the app already supports it or its architecture makes it straightforward. If supported, design both themes intentionally; do not simply invert colors.

### 2. Header and page introduction
- Refine the top app bar with a well-aligned **Eddembe** wordmark/title.
- Keep language and settings actions if they already work, but make them visually quieter and align them consistently.
- Use recognizable icons, consistent sizing, and proper spacing.
- Keep the headline **“What is happening?”** prominent but not oversized.
- Improve the supporting copy to be short, calm, and easy to understand. Suggested copy:
  **“Choose what best describes your situation. We’ll guide you through the next steps.”**
- Avoid excessive empty space above or below the heading.

### 3. Situation/category cards
Create four polished, tappable category rows for the existing categories:
1. **Housing** — “My landlord wants me out” — supporting text: “Eviction notices, rent, deposits or locked doors.”
2. **Work** — “Problem at work” — supporting text: “Unpaid wages, dismissal, contracts or unfair treatment.”
3. **Land** — “Land dispute” — supporting text: “Boundaries, land purchases or being told to leave.”
4. **Government information** — “I need information from government” — supporting text: “Request public records or official documents.”

Design guidance:
- Preserve the meaning and intended flow of the existing categories.
- Consider a compact category label, title, and one-line or two-line description with a clear trailing arrow.
- Use a consistent icon container and consistent card padding, corner radius, and spacing.
- Use simple, familiar icons from the icon library already installed in the project. Avoid emoji and decorative illustrations that do not aid recognition.
- Use subtle borders or restrained elevation to separate cards from the background. Do not use heavy shadows.
- Make the entire card tappable, not only the arrow.
- Provide clear pressed, focused, and selected states where applicable.
- Ensure text wraps gracefully on small screens and no content is clipped.
- Reduce the oversized, visually heavy feel of the current cards. Keep the screen scannable without making the touch targets too small.
- Do not introduce new categories or change existing navigation destinations.

### 4. Bottom navigation
Keep the four existing destinations:
- Home
- Ask
- Scan
- My cases

Refine the navigation using a Material 3-inspired approach:
- Make the active destination clear using a restrained green selected state and readable label.
- Use consistent icon sizes, label styles, spacing, and alignment.
- Keep inactive destinations visible without making them compete with the content.
- Respect system navigation insets and safe areas.
- Prevent the navigation bar from covering scrollable content.
- Confirm each item still navigates to its existing destination and the selected state updates correctly.

### 5. Typography and spacing
- Use the project's existing typography system if one exists; otherwise use a clean, legible sans-serif.
- Establish a clear hierarchy for page title, category title, description, labels, and navigation.
- Avoid using too many font sizes or weights.
- Use a consistent spacing scale, preferably based on 4 dp/px increments appropriate to the framework.
- Align content to a consistent horizontal grid.
- Keep body text readable and avoid overly pale gray text.
- Use responsive layout rules rather than fixed dimensions that break on different screen sizes.

### 6. Accessibility and usability
- Meet WCAG AA contrast targets where applicable.
- Make interactive targets approximately 48 dp high/wide or larger where practical.
- Ensure icons have appropriate semantic labels and screen-reader descriptions.
- Do not rely on color alone to communicate selection or meaning.
- Support larger system font sizes and text scaling.
- Test narrow screens and long translations so the layout does not overflow.
- Respect reduced-motion preferences if animations are added.
- Use subtle, purposeful transitions only; avoid unnecessary animation.

## Interaction and product behavior
- Treat this as a UI/UX redesign, not a rewrite of the app's business logic.
- Inspect the existing project before making changes. Identify the framework, routing, theme setup, reusable components, icon library, and current screen implementation.
- Preserve all existing actions, navigation routes, localization/language controls, settings actions, scan behavior, Ask flow, and My cases behavior.
- Do not replace real functionality with mock buttons, placeholder screens, or hard-coded navigation.
- Do not remove existing functionality to make the screen easier to redesign.
- Reuse existing components and design tokens where sensible; create reusable components for repeated UI patterns.
- Keep the implementation maintainable and consistent with the project's current architecture.

## Suggested screen structure
1. Top app bar: Eddembe title/brand, language action, settings action.
2. Page introduction: headline and concise supporting text.
3. Optional small section label such as **“Choose a topic”** if it improves hierarchy.
4. Four refined category cards in a vertically scrollable content area.
5. Bottom navigation: Home, Ask, Scan, My cases.

Do not add promotional banners, unnecessary statistics, decorative charts, large hero illustrations, or extra calls to action. The primary task is helping a user choose the right category quickly.

## Implementation workflow
1. Inspect the repository and locate the current home screen, theme, navigation, and reusable UI components.
2. Identify the framework and follow its idiomatic design and accessibility practices.
3. Briefly state the files/components you plan to change, then implement the redesign.
4. Build reusable category-card and navigation styling where appropriate.
5. Preserve the current functionality and data flow.
6. Run the available formatter, static analysis/linter, and relevant tests.
7. Fix any errors introduced by the changes.
8. If a simulator, emulator, or screenshot workflow is available, inspect the redesigned screen at:
   - a typical phone size,
   - a narrow phone size,
   - a larger text scale.
9. Check for overflow, clipped labels, uneven spacing, inconsistent icons, poor contrast, and bottom navigation overlap.
10. Summarize what changed, list the files modified, and report which checks were run and their results. Be honest about any checks that could not be run.

## Acceptance criteria
The redesign is complete only when:
- The screen looks noticeably more professional and visually balanced than the supplied screenshot.
- It has a clear visual hierarchy and consistent spacing.
- The color palette is restrained, accessible, and trust-oriented.
- All four categories remain present and easy to scan.
- The four bottom-navigation destinations remain functional.
- Language and settings actions remain functional.
- Layout adapts to different screen widths and larger text.
- There are no avoidable overflow, clipping, or safe-area issues.
- Existing business logic and routes are preserved.
- The code follows the project's current architecture and passes available checks.

## Final instruction
**Make the changes in the existing codebase. Do not only provide a design description or a code snippet.** Use good judgment to deliver the most polished implementation consistent with the current stack. Prioritize clarity, trust, accessibility, and real-world usability over visual decoration.
"""
path = Path("/mnt/data/eddembe_ui_redesign_prompt.md")
path.write_text(content, encoding="utf-8")
print(f"Created: {path}")
