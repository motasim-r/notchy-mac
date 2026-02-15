import type { ReactElement } from "react";

interface ScriptEditorProps {
  scriptText: string;
  onChange: (text: string) => void;
}

export function ScriptEditor({ scriptText, onChange }: ScriptEditorProps): ReactElement {
  return (
    <section className="editor-card">
      <header className="card-header">
        <h2>Script</h2>
        <p>Edits sync instantly to the notch teleprompter.</p>
      </header>
      <textarea
        className="script-textarea"
        value={scriptText}
        onChange={(event) => onChange(event.target.value)}
        placeholder="Paste your talking points here..."
      />
    </section>
  );
}
