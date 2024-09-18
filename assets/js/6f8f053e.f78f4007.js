"use strict";(self.webpackChunk_giraffechain_sdk_docs=self.webpackChunk_giraffechain_sdk_docs||[]).push([[664],{9595:(e,n,s)=>{s.r(n),s.d(n,{assets:()=>c,contentTitle:()=>r,default:()=>h,frontMatter:()=>l,metadata:()=>o,toc:()=>d});var t=s(4848),i=s(8453);const l={description:"Information about the data types used in Giraffe Chain.",sidebar_position:7},r="Data Models",o={id:"models",title:"Data Models",description:"Information about the data types used in Giraffe Chain.",source:"@site/docs/models.md",sourceDirName:".",slug:"/models",permalink:"/docs/models",draft:!1,unlisted:!1,tags:[],version:"current",sidebarPosition:7,frontMatter:{description:"Information about the data types used in Giraffe Chain.",sidebar_position:7},sidebar:"tutorialSidebar",previous:{title:"Faucet",permalink:"/docs/faucet"},next:{title:"Protocol Development",permalink:"/docs/protocol-development"}},c={},d=[{value:"Transaction",id:"transaction",level:2},{value:"TransactionInput",id:"transactioninput",level:2},{value:"TransactionOutput",id:"transactionoutput",level:2},{value:"Witness",id:"witness",level:2},{value:"Value",id:"value",level:2},{value:"Graph Entry",id:"graph-entry",level:2},{value:"Vertex",id:"vertex",level:2},{value:"Edge",id:"edge",level:2},{value:"Block Header",id:"block-header",level:2},{value:"Block Body",id:"block-body",level:2},{value:"Full Block Body",id:"full-block-body",level:2},{value:"Block",id:"block",level:2},{value:"Full Block",id:"full-block",level:2}];function a(e){const n={a:"a",h1:"h1",h2:"h2",header:"header",li:"li",p:"p",strong:"strong",ul:"ul",...(0,i.R)(),...e.components};return(0,t.jsxs)(t.Fragment,{children:[(0,t.jsx)(n.header,{children:(0,t.jsx)(n.h1,{id:"data-models",children:"Data Models"})}),"\n",(0,t.jsxs)(n.p,{children:["Giraffe Chain's models and data types are primarily defined using Protobuf and then compiled into target languages. These definitions are located ",(0,t.jsx)(n.a,{href:"https://github.com/GiraffeChain/giraffe/blob/main/proto/models/core.proto",children:"here"}),"."]}),"\n",(0,t.jsx)(n.p,{children:"While not a comprehensive list, here is a general summary:"}),"\n",(0,t.jsx)(n.h2,{id:"transaction",children:"Transaction"}),"\n",(0,t.jsx)(n.p,{children:"Represents a change to the ledger - the spending of inputs and creation of outputs."}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"inputs"}),": A list of things being spent"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"outputs"}),": A list of things being created"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"attestation"}),": Provides authorization that the inputs can be spent"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"rewardParentBlockId"}),": Only provided by block producers, this is the ID of the block that came before the one being created"]}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"transactioninput",children:"TransactionInput"}),"\n",(0,t.jsx)(n.p,{children:"Spends a TransactionOutput."}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"reference"}),": The reference to the UTxO to spend"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"value"}),': A copy of the "value" of the UTxO to spend']}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"transactionoutput",children:"TransactionOutput"}),"\n",(0,t.jsx)(n.p,{children:"An entry in the blockchain ledger."}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"lockAddress"}),": The hash of a lock that secures this output"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"value"}),": Contains the quantity, account, and graph information"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"account"}),": A reference to a UTxO containing an account registration. When provided, funds will be added to the staking account."]}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"witness",children:"Witness"}),"\n",(0,t.jsx)(n.p,{children:"Provides authorization proof to spend a UTxO."}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"lockAddress"}),": A hash of the lock"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"lock"}),': The full set of constraints that need to be satisfied. Should correspond to the "lockAddress" property.']}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"key"}),": Satisfies the constraints of the lock."]}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"value",children:"Value"}),"\n",(0,t.jsx)(n.p,{children:"The contents of a Transaction Output."}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"quantity"}),": The number of tokens"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"accountRegistration"}),": An optional registration for a new staking account"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"graphEntry"}),": An optional record in the graph database"]}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"graph-entry",children:"Graph Entry"}),"\n",(0,t.jsx)(n.p,{children:"One of:"}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"vertex"}),": An entity"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"edge"}),": A relationship between two vertices"]}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"vertex",children:"Vertex"}),"\n",(0,t.jsx)(n.p,{children:"An entity or data object of a graph database"}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"label"}),": A class or group name"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"data"}),": A JSON object"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"edgeLockAddress"}),": A constraint that must be satisfied in order to connect to this vertex"]}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"edge",children:"Edge"}),"\n",(0,t.jsx)(n.p,{children:"A connection or relationship between two vertices"}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"label"}),": A class or group name"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"data"}),": A JSON object"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"a"}),": A reference to a vertex output"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"b"}),": A reference to a vertex output"]}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"block-header",children:"Block Header"}),"\n",(0,t.jsx)(n.p,{children:"Holds metadata about a block, primarily for the purposes of consensus."}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"parentHeaderId"}),': The ID of the block that came before this one. This field is what makes a blockchain a "chain"']}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"parentSlot"}),': The "slot" of the block that came before this one.']}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"txRoot"}),": A commitment to the Block Body"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"timestamp"}),": The UTC UNIX timestamp at which the block was created"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"height"}),": The 1-based index of the block within the chain"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"slot"}),": The window of time in which the block was created."]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"stakerCertificate"}),": A certificate containing proof-of-eligibility as well as a signature of the block"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"account"}),": A reference to a UTxO containing an account registration"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"settings"}),": A key-value map of changes to the protocol"]}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"block-body",children:"Block Body"}),"\n",(0,t.jsx)(n.p,{children:"Holds just the transaction IDs of a block."}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"transactionIds"}),": The IDs of the transactions included in a block."]}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"full-block-body",children:"Full Block Body"}),"\n",(0,t.jsx)(n.p,{children:"Holds the full transaction data of a block."}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"transactions"}),": The transactions included in a block."]}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"block",children:"Block"}),"\n",(0,t.jsx)(n.p,{children:"Holds the header and body of a block."}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"header"}),": The Block Header of the block"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"body"}),": The block body of the block"]}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"full-block",children:"Full Block"}),"\n",(0,t.jsx)(n.p,{children:"Holds the header and full body of a block."}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"header"}),": The Block Header of the block"]}),"\n",(0,t.jsxs)(n.li,{children:[(0,t.jsx)(n.strong,{children:"fullBody"}),": The full block body of the block"]}),"\n"]})]})}function h(e={}){const{wrapper:n}={...(0,i.R)(),...e.components};return n?(0,t.jsx)(n,{...e,children:(0,t.jsx)(a,{...e})}):a(e)}},8453:(e,n,s)=>{s.d(n,{R:()=>r,x:()=>o});var t=s(6540);const i={},l=t.createContext(i);function r(e){const n=t.useContext(l);return t.useMemo((function(){return"function"==typeof e?e(n):{...n,...e}}),[n,e])}function o(e){let n;return n=e.disableParentContext?"function"==typeof e.components?e.components(i):e.components||i:r(e.components),t.createElement(l.Provider,{value:n},e.children)}}}]);