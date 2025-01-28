import React, { useContext, useRef } from "react";
import AppearanceContext from "../../contexts/AppearanceContext";
import * as S from "../GenericalStyles";

function TypeList({ indexType, handleChangeType, types, shop }) {
  const { appearance } = useContext(AppearanceContext);
  const headerListRef = useRef();

  return (
    <S.TypeList ref={headerListRef}>
      {appearance[shop].drawables.map((item, index) => (
        <S.TypeItem
          key={index}
          className={index === indexType ? "active" : ""}
          onClick={() => handleChangeType(index, item)}
        >
          <S.TypeImage
            src={`https://host-two-ochre.vercel.app/files/peds/${shop}/${index}.png`}
          />
          {/* <S.TypeTitle>{types[index].title}</S.TypeTitle> */}
        </S.TypeItem>
      ))}
    </S.TypeList>
  );
}

export default TypeList;
