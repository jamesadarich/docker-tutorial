import * as React from  "react";
import { render } from "react-dom";

class AppComponent extends React.PureComponent {
    public render() {
        return <section>
                  <h1>Docker Tutorial</h1>
                  <p>You're going to have the greatest time with Docker</p>
               </section>;
    }
}

render(<AppComponent />, document.querySelector("body"));
