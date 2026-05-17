import { useAccount, useConnect, useDisconnect, useChainId, useSwitchChain } from "wagmi";
import { injected } from "wagmi/connectors";
import { arbitrumSepolia } from "wagmi/chains";
import { useState } from "react";

const SUBGRAPH_URL = import.meta.env.VITE_SUBGRAPH_URL ?? "";

export default function App() {
  const { address, isConnected } = useAccount();
  const { connect, isPending, error: connectError } = useConnect();
  const { disconnect } = useDisconnect();
  const chainId = useChainId();
  const { switchChain } = useSwitchChain();
  const [subgraphMints, setSubgraphMints] = useState<string>("");

  const wrongNetwork = isConnected && chainId !== arbitrumSepolia.id;

  async function loadSubgraph() {
    if (!SUBGRAPH_URL) {
      setSubgraphMints("Set VITE_SUBGRAPH_URL to query indexed mints.");
      return;
    }
    const res = await fetch(SUBGRAPH_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query: "{ mintEvents(first: 5) { id amount } }" }),
    });
    const json = await res.json();
    setSubgraphMints(JSON.stringify(json.data ?? json.errors, null, 2));
  }

  return (
    <main style={{ fontFamily: "system-ui", padding: 24, maxWidth: 720 }}>
      <h1>RWA Tokenization Platform</h1>
      <p>ERC-20 collateral · ERC-4626 vault · DAO governance · L2</p>

      {!isConnected ? (
        <button
          disabled={isPending}
          onClick={() => connect({ connector: injected() })}
        >
          Connect MetaMask
        </button>
      ) : (
        <button onClick={() => disconnect()}>Disconnect {address}</button>
      )}

      {connectError && <p role="alert">Wallet error: {connectError.message}</p>}

      {wrongNetwork && (
        <p role="alert">
          Wrong network.{" "}
          <button onClick={() => switchChain({ chainId: arbitrumSepolia.id })}>
            Switch to Arbitrum Sepolia
          </button>
        </p>
      )}

      <section style={{ marginTop: 24 }}>
        <h2>Indexed data (The Graph)</h2>
        <button onClick={loadSubgraph}>Load recent mints</button>
        <pre>{subgraphMints}</pre>
      </section>

      <section style={{ marginTop: 24 }}>
        <h2>Actions (wire ABIs after deploy)</h2>
        <ul>
          <li>Deposit to vault</li>
          <li>AMM swap</li>
          <li>Vote on active proposal</li>
        </ul>
      </section>
    </main>
  );
}
