import * as React from "react";
import Modal from "@cloudscape-design/components/modal";
import Box from "@cloudscape-design/components/box";
import SpaceBetween from "@cloudscape-design/components/space-between";
import Button from "@cloudscape-design/components/button";

export const ConsentModal = ({ visible, setVisible }) => {
    return (
      <Modal
        onDismiss={() => setVisible(false)}
        visible={visible}
        footer={
          <Box float="right">
            <SpaceBetween direction="horizontal" size="xs">
              <Button variant="link" onClick={() => setVisible(false)}>
                Cancel
              </Button>
              <Button variant="primary">Confirmed</Button>
            </SpaceBetween>
          </Box>
        }
        header={<React.Fragment>Recording Consent</React.Fragment>}
      >
        Advise the patient that the consultation will be recorded and obtain their
        consent.
      </Modal>
    );
  };