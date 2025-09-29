import React from "react";
import { Container, Row, Col } from "react-bootstrap";
// container where you can add data
const FormContainer = ({ children }) => {
  return (
    <Container>
      <Row className="justify-content-md-center">
        <Col xs={12} md={12}>
          {children}
        </Col>
      </Row>
    </Container>
  );
};

export default FormContainer;
