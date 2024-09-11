"use strict";(self.webpackChunk_giraffechain_sdk_docs=self.webpackChunk_giraffechain_sdk_docs||[]).push([[543],{1373:(e,n,i)=>{i.r(n),i.d(n,{assets:()=>c,contentTitle:()=>r,default:()=>h,frontMatter:()=>l,metadata:()=>d,toc:()=>s});var t=i(4848),o=i(8453);const l={title:"Protocol Development",description:"Information about developing, testing, and contributing to the protocol.",sidebar_position:6},r="Protocol Development",d={id:"protocol-development",title:"Protocol Development",description:"Information about developing, testing, and contributing to the protocol.",source:"@site/docs/protocol-development.md",sourceDirName:".",slug:"/protocol-development",permalink:"/docs/protocol-development",draft:!1,unlisted:!1,tags:[],version:"current",sidebarPosition:6,frontMatter:{title:"Protocol Development",description:"Information about developing, testing, and contributing to the protocol.",sidebar_position:6},sidebar:"tutorialSidebar",previous:{title:"dApp Development",permalink:"/docs/dapp-development"}},c={},s=[{value:"Dependencies",id:"dependencies",level:2},{value:"Launch",id:"launch",level:2},{value:"Implementation &amp; Directory Structure",id:"implementation--directory-structure",level:2}];function a(e){const n={code:"code",h1:"h1",h2:"h2",header:"header",li:"li",ol:"ol",p:"p",ul:"ul",...(0,o.R)(),...e.components};return(0,t.jsxs)(t.Fragment,{children:[(0,t.jsx)(n.header,{children:(0,t.jsx)(n.h1,{id:"protocol-development",children:"Protocol Development"})}),"\n",(0,t.jsx)(n.p,{children:"Contribution guidelines haven't yet been formalized. Ideas and suggestions are welcome in this regard. For now, if you have a change you'd like to make, pleae feel free to submit a Pull Request!"}),"\n",(0,t.jsx)(n.h2,{id:"dependencies",children:"Dependencies"}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsx)(n.li,{children:"JDK 17+"}),"\n",(0,t.jsx)(n.li,{children:"SBT/Scala"}),"\n",(0,t.jsx)(n.li,{children:"Flutter"}),"\n",(0,t.jsx)(n.li,{children:"NodeJS 20+"}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"launch",children:"Launch"}),"\n",(0,t.jsxs)(n.ol,{children:["\n",(0,t.jsxs)(n.li,{children:["Start the relay node.","\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsx)(n.li,{children:(0,t.jsx)(n.code,{children:"cd scala"})}),"\n",(0,t.jsx)(n.li,{children:(0,t.jsx)(n.code,{children:"sbt relay/run"})}),"\n"]}),"\n"]}),"\n",(0,t.jsxs)(n.li,{children:["Start the wallet.","\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsx)(n.li,{children:(0,t.jsx)(n.code,{children:"cd ../dart/wallet"})}),"\n",(0,t.jsx)(n.li,{children:(0,t.jsx)(n.code,{children:"flutter run"})}),"\n"]}),"\n"]}),"\n"]}),"\n",(0,t.jsx)(n.h2,{id:"implementation--directory-structure",children:"Implementation & Directory Structure"}),"\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:["Models are defined in protobuf, and you can find them in the ",(0,t.jsx)(n.code,{children:"proto/"})," directory.","\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:["Misc/support files are defined in ",(0,t.jsx)(n.code,{children:"external_proto/"})]}),"\n",(0,t.jsx)(n.li,{children:"Protobuf models are served over JSON-RPC, not gRPC"}),"\n"]}),"\n"]}),"\n",(0,t.jsxs)(n.li,{children:["The backend/relay node is defined in Scala, and you can find it in the ",(0,t.jsx)(n.code,{children:"scala/"})," directory.","\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:["Most of the code is defined in the ",(0,t.jsx)(n.code,{children:"node"})," module"]}),"\n",(0,t.jsxs)(n.li,{children:["Compiled protobuf files are defined in the ",(0,t.jsx)(n.code,{children:"protobuf"})," module"]}),"\n"]}),"\n"]}),"\n",(0,t.jsxs)(n.li,{children:["The wallet is defined in Dart/Flutter, and you can find it in the ",(0,t.jsx)(n.code,{children:"dart/"})," directory.","\n",(0,t.jsxs)(n.ul,{children:["\n",(0,t.jsxs)(n.li,{children:["The ",(0,t.jsx)(n.code,{children:"sdk"})," directory contains a client, codecs, wallet, and miscellaneous utilities for interacting with the chain"]}),"\n",(0,t.jsxs)(n.li,{children:["The ",(0,t.jsx)(n.code,{children:"wallet"})," directory is an application with a built-in wallet, block explorer, staker, and social explorer"]}),"\n"]}),"\n"]}),"\n",(0,t.jsxs)(n.li,{children:["The SDK is defined in Typescript, and you can find it in the ",(0,t.jsx)(n.code,{children:"typescript/sdk/"})," directory."]}),"\n"]})]})}function h(e={}){const{wrapper:n}={...(0,o.R)(),...e.components};return n?(0,t.jsx)(n,{...e,children:(0,t.jsx)(a,{...e})}):a(e)}},8453:(e,n,i)=>{i.d(n,{R:()=>r,x:()=>d});var t=i(6540);const o={},l=t.createContext(o);function r(e){const n=t.useContext(l);return t.useMemo((function(){return"function"==typeof e?e(n):{...n,...e}}),[n,e])}function d(e){let n;return n=e.disableParentContext?"function"==typeof e.components?e.components(o):e.components||o:r(e.components),t.createElement(l.Provider,{value:n},e.children)}}}]);