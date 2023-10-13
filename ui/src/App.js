import "./App.css";
import { MetaMaskProvider } from "./contexts/MetaMask";
import MetaMask from "./components/MetaMask.js";

const config = {
  token0Address: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
  token1Address: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
  poolAddress: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
  managerAddress: "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
  ABIs: {
    ERC20: require("./abi/ERC20.json"),
    Pool: require("./abi/Pool.json"),
    Manager: require("./abi/Manager.json"),
  },
};

const App = () => {
  return (
    <MetaMaskProvider>
      <div className="App flex flex-col justify-between items-center w-full h-full">
        <MetaMask />
        <footer></footer>
      </div>
    </MetaMaskProvider>
  );
};

export default App;
