# Declarative WebMCP support

AribaWeb supports the WebMCP declarative form API through opt-in bindings on
existing HTML form components.  The integration emits WebMCP HTML attributes
only when the new bindings are present, so existing forms render as before.

## Form tool bindings

Use these bindings on `a:Form`:

* `toolName` renders the form `toolname` attribute.
* `toolDescription` renders the form `tooldescription` attribute.
* `toolAutoSubmit="$true"` renders the boolean `toolautosubmit` attribute.

Example:

```html
<a:Form action="$createTicket"
        toolName="create_ticket"
        toolDescription="Create a support ticket"
        toolAutoSubmit="$true">
    <a:TextField name="summary"
                 value="$summary"
                 toolParamDescription="Short issue summary"/>
    <a:TextArea name="details"
                value="$details"
                toolParamDescription="Detailed issue description"/>
    <w:TextButton action="$createTicket" label="Create"/>
</a:Form>
```

## Parameter bindings

Use `toolParamDescription` on these input components to render
`toolparamdescription`:

* `a:TextField`
* `a:TextArea`
* `a:Popup`
* `a:Checkbox`
* `a:RadioButton`

WebMCP derives tool parameters from normal form controls.  Bind stable `name`
values where the component supports them so the generated parameter schema is
stable and understandable to an agent.

## Browser behavior

Declarative WebMCP is implemented by supporting browsers.  AribaWeb does not
register imperative `document.modelContext` tools, add a JavaScript polyfill, or
change form submission semantics.  If `toolAutoSubmit` is not set, the browser
is expected to surface the active tool form and submit it through the normal
form path after user or agent interaction.

Current public references:

* W3C Web Machine Learning Community Group WebMCP draft:
  https://webmachinelearning.github.io/webmcp/
* Chrome WebMCP overview:
  https://developer.chrome.com/docs/ai/webmcp
* Chrome declarative WebMCP API:
  https://developer.chrome.com/docs/ai/webmcp/declarative-api
* Declarative API explainer:
  https://github.com/webmachinelearning/webmcp/blob/main/declarative-api-explainer.md
