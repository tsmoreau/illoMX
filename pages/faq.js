import React, { Component } from "react";
import ReactDOM from "react-dom";
import Faq from "react-faq-component";

const data = {
  title: "faq",
  rows: [
    {
      title: "what is illo.mx?",
      content:
        "illo.mx is a nft marketplace dapp running on the tao blockchain."
    },
    {
      title: "why all the dust?",
      content:
        "illo.mx is currently in public aplha and much about it is subject to change. please do not use it for more than testing and amusement for now."
    },
    {
      title: "what's tao?",
      content: "tao is a smaller EVM compatible blockchain."
    }
  ]
};

const styles = {
  // bgColor: 'white',
  titleTextColor: "black",
  rowTitleColor: "black",
  rowContentPaddingBottom: "10px",
  rowContentPaddingLeft: "10px",
  rowContentPaddingRight: "10px"
  // rowContentColor: 'grey',
  // arrowColor: "red",
};

const config = {
  // animate: true,
  // arrowIcon: "V",
  // tabFocus: true
};

export default class App extends Component {
  render() {
    return (
      <div>
        <div class="px-5 md:px-64 lg:px-96 ">
          <Faq data={data} styles={styles} config={config} />
        </div>
      </div>
    );
  }
}
