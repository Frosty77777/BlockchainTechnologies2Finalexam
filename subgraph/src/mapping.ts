import { Minted as MintedEvent, Burned as BurnedEvent } from "../generated/RWACollateralToken/RWACollateralToken";
import { Asset, MintEvent, BurnEvent } from "../generated/schema";
import { BigInt, Bytes } from "@graphprotocol/graph-ts";

export function handleMinted(event: MintedEvent): void {
  let asset = Asset.load(event.address.toHex());
  if (asset == null) {
    asset = new Asset(event.address.toHex());
    asset.assetId = "unknown";
    asset.token = event.address;
    asset.totalMinted = BigInt.zero();
    asset.totalBurned = BigInt.zero();
  }
  asset.totalMinted = asset.totalMinted.plus(event.params.amount);
  asset.save();

  let id = event.transaction.hash.toHex() + "-" + event.logIndex.toString();
  let mint = new MintEvent(id);
  mint.asset = asset.id;
  mint.issuer = event.params.issuer;
  mint.to = event.params.to;
  mint.amount = event.params.amount;
  mint.timestamp = event.block.timestamp;
  mint.blockNumber = event.block.number;
  mint.save();
}

export function handleBurned(event: BurnedEvent): void {
  let asset = Asset.load(event.address.toHex());
  if (asset == null) return;
  asset.totalBurned = asset.totalBurned.plus(event.params.amount);
  asset.save();

  let burn = new BurnEvent(event.transaction.hash.toHex() + "-b-" + event.logIndex.toString());
  burn.asset = asset.id;
  burn.from = event.params.from;
  burn.amount = event.params.amount;
  burn.timestamp = event.block.timestamp;
  burn.save();
}
