const Message = ({ variant = "info", children }) => {
  return <div className={`alert alert-${variant}`}>{children}</div>;
};

export default Message;
