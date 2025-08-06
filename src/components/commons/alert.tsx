import * as React from "react";
import Alert from "@cloudscape-design/components/alert";

export default () => {
  return (
    <Alert
      dismissible
      statusIconAriaLabel="Info"
      header={
        <React.Fragment>
          These notes have been generated using AI, please
          carefully review them for accuracy and
          completeness before submitting.
        </React.Fragment>
      }
    />
  );
}