import { Row, Col } from "react-bootstrap";
import Product from "../components/Product";
// vvv IMPORT THE NEW HOOK ALONG WITH THE EXISTING ONE vvv
import {
  useGetProductsQuery,
  useGetTestMessageQuery, // 1. Import the new hook
} from "../slices/productsApiSlice";
// ^^^ IMPORT THE NEW HOOK ALONG WITH THE EXISTING ONE ^^^
import Loader from "../components/Loader";
import Message from "../components/Message";
import { Link, useParams } from "react-router-dom";
import Paginate from "../components/Paginate";
import ProductCarousel from "../components/ProductCarousel";
import Meta from "../components/Meta";

const HomeScreens = () => {
  const { pageNumber, keyword } = useParams();
  const { data, isLoading, error } = useGetProductsQuery({
    keyword,
    pageNumber,
  });

  // 2. Call the new hook to fetch data.
  // We use "data: testData" to rename 'data' so it doesn't conflict
  // with the 'data' from useGetProductsQuery.
  const { data: testData } = useGetTestMessageQuery();

  return (
    <>
      <Meta />
      {!keyword ? (
        <ProductCarousel />
      ) : (
        <Link to="/" className="btn btn-light">
          Go Back
        </Link>
      )}
      {isLoading ? (
        <Loader />
      ) : error ? (
        <Message variant="danger">
          {error?.data?.message || error.error}
        </Message>
      ) : (
        <>
          <h1>Latest products</h1>

          {/* 3. Render the message from the new endpoint */}
          {testData && <Message variant="success">{testData.message}</Message>}

          <Row>
            {data.products.map((product) => (
              <Col key={product._id} sm={12} md={6} lg={4} xl={3}>
                <Product product={product} />
              </Col>
            ))}
          </Row>
          <Paginate
            pages={data.pages}
            page={data.page}
            keyword={keyword ? keyword : ""}
          />
        </>
      )}
    </>
  );
};

export default HomeScreens;
