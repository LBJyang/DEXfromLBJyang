import { useContext } from "react";
import { MetaMaskContext } from "./components/MetaMask";
import "./MetaMask.css";

const chainIdtoChainName = (chain) => {
  switch (chain) {
    case "0x1":
      return "Mainnet";
    case "0x7a69":
      return "Anvil";
    default:
      return "Unknown chain!";
  }
};
const shortAddress = (address) =>
  address.slice(0, 6) + "..." + address.slice(-4);

const statusConnected = (account, chain) => {
  return (
    <span>
      Connected to {chainIdtoChainName(chain)} as {shortAddress(account)}!
    </span>
  );
};
const statusNotConnected = (connect) => {
  return (
    <span>
      MetaMask is not connected!<button onClick={connect}>connect</button>
    </span>
  );
};

const renderStatus = (status, account, chain, connect) => {
  switch (status) {
    case "connected":
      return statusConnected(account, chain);
    case "not_connected":
      return statusNotConnected(connect);
    case "not_installed":
      return <span>MetaMask is not installed</span>;
    default:
      return;
  }
};

const MetaMask = () => {
  const context = useContext(MetaMaskContext);
  return (
    <section className="MetaMaskContainer">
      {renderStatus(
        context.status,
        context.account,
        context.chain,
        context.connect
      )}
    </section>
  );
};
export default MetaMask;
