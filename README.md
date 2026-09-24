원본 `고군분투.swf`(Flash 8 / ActionScript 2)를 **역컴파일해서 게임 로직 그대로 리메이크**하고,
**PPO로 신경망을 학습**시켜 스스로 클리어하게 만든 프로젝트입니다.

## 화면 구성 (탭)
| 탭 | 내용 |
|---|---|
| PLAY | AI / 직접 플레이, 1x~32x 배속, 시작 레벨, 자동 재시작, 사운드, 모델 선택 |
| BATTLE | 1~10단계 AI(또는 사람) 두 선수가 같은 맵으로 동시에 달리는 거리+코인 점수 대결 |
| NETWORK | GRAPH(활성화+연결선) / WEIGHTS(가중치 히트맵) / INPUTS(64또는 84개 입력 이름·값·중요도) |
| TRAIN | 브라우저 안에서 PPO 학습 입력 64·84 선택, 코인 보상 계수, 학습 곡선, 내보내기/가져오기 |

## 폴더
```
gogun_ai.html                     결과물(실행 파일) — 에셋·사운드·시뮬레이터·가중치·사다리·학습기 전부 내장
game/
  sim.js  sim.c  data.h  gogun_data.json      게임 로직(JS 기준 구현 / C 포트). data.h·gogun_data.json = 원본 맵·코인 데이터
  render.js                        SWF 타임라인 런타임 + 화면 렌더러
  audio.js                         WebAudio 사운드 엔진 (SetGame.as의 재생/정지 규칙)
  battle.js                        BATTLE 탭 로직 (동시 진행 2레인, 거리+코인 점수, 전적)
  trainer.js worker_glue.js trainctl.js       브라우저 PPO(학습기 / 워커 진입점 / 코디네이터), 64·84 입력 모두 지원
  netview.js                       신경망 시각화(GRAPH/WEIGHTS/INPUTS), 64·84 입력 모두 지원
  app.js template.html build_html.py          UI, 단일 HTML 빌더
  train.py                         오프라인 PPO(CPU, numpy) — OBSV=1|2, ITEMS=0|1, --coin_w 로 코인 학습
  train_gpu.py                     GPU(PyTorch) 또는 numpy 백엔드 PPO — OpenMP C 시뮬레이터, --obs 1|2 --coin_w
  colab_gpu_train.ipynb            Colab에서 GPU로 바로 학습하는 노트북
  eval_c.py eval_js.js eval_battle.py         클리어율 평가 / 거리+코인 대결 점수 평가(BATTLE과 같은 공식)
  make_ladder.py                   후보 체크포인트들을 대결 점수로 평가해 1~10단계 사다리(ladder.json) 생성
  export_ck.py                     .npz 체크포인트 → 웹 페이지용 weights.json (64·84 입력 자동 인식)
  test_grad.js test_train_node.js test_continue_node.js   브라우저 학습기 검증(기울기 유한차분 등)
  difftest_*.js/py                 JS<->C 시뮬레이터 프레임 단위 동일성 검증(관측 v1/v2 포함)
  ui_check.py train_check.py       헤드리스 크롬 UI/학습 자동 점검
  weights.json                     기본(PRETRAINED) 가중치 — 사용자 제공 코인 인식 모델(관측 84, 은닉 128)
  weights_survival_previous.json   이전 기본 모델(생존 전용, 관측 64) — 참고/비교용
  checkpoint_final.npz              이전 기본 모델의 학습 재개용 체크포인트(.npz)
  weights_coin.json checkpoint_coin_example.npz   자체 미세조정한 코인 인식 예시 가중치(BATTLE TIER 9와 동일)
  ck_coin_original_upload.json      사용자가 준 원본 파일 그대로 보관
  sounds.json                      추출한 사운드 14개(base64 MP3 뱅크)
  ladder.json                      BATTLE 1~10단계 상대 데이터(가중치 포함)
  scene.json                       SWF에서 추출한 도형·스프라이트·비트맵(WebP)
  build.sh                         libsim.so(단일 스레드) + libsim_omp.so(OpenMP) 빌드
tools/                             SWF 파서·AS2 역컴파일러·에셋 추출기(도형/비트맵/사운드), 순수 파이썬
decompiled/                        역컴파일한 원본 클래스(SetGame, MapData, ItemData, CoinItem ...)
```

## 사용법
```sh
# 1) 그냥 보기: gogun_ai.html 을 브라우저로 열기 (화면을 한 번 클릭하면 소리가 켜집니다)

# 2) GPU로 빠르게 학습 (로컬에 CUDA GPU가 있다면)
cd game && ./build.sh && pip install torch    # 이미 설치돼 있다면 생략
python3 train_gpu.py --device cuda --envs 8192 --minutes 10 --out ck_new                       # 생존 전용
python3 train_gpu.py --device cuda --obs 2 --coin_w 0.001 --init ck_new_ema.npz --minutes 10 --out ck_coin  # 코인 인식 이어서
python3 export_ck.py ck_new_ema.npz weights.json                                                # 웹 페이지 TRAIN > IMPORT 로 불러오기
# GPU가 없다면 Colab에서 colab_gpu_train.ipynb 를 열고 런타임을 GPU로 바꾼 뒤 위에서부터 실행하세요.

# 3) 대결 사다리 다시 만들기
python3 eval_battle.py ck_new_ema.npz checkpoint_final.npz --games 200         # 거리+코인 점수로 평가
python3 make_ladder.py --cands 'ck_*_ema_it*.npz' checkpoint_final.npz --games 100 --out ladder.json
python3 build_html.py weights.json gogun_ai.html                               # ladder.json / sounds.json 은 자동으로 포함됩니다

# 4) CPU만으로 빠른 재학습·평가 (기존 경로, 여전히 지원)
python3 train.py --init checkpoint_final.npz --iters 200 --out ck                              # 이어서 학습
OBSV=2 ITEMS=1 python3 train.py --init checkpoint_final.npz --coin_w 0.001 --iters 500 --out ck_coin   # 코인 인식으로 전환
python3 eval_c.py checkpoint_final.npz 1000 12345                                               # 처음부터 끝까지 1000판 클리어율
python3 ui_check.py gogun_ai.html                                                               # 헤드리스 크롬: 화면/코인/이모티콘/학습/내보내기 자동 점검

# 5) 원본 SWF에서 전부 다시 추출 (결과는 동봉 파일과 바이트 단위로 동일)
python3 tools/decompile_all.py 고군분투.swf decompiled
python3 tools/extract_data.py decompiled game/gogun_data.json && python3 tools/gen_data_h.py game/gogun_data.json game/data.h
mkdir work && cd work && python3 ../tools/extract_bitmaps.py ../고군분투.swf bmp && python3 ../tools/build_scene.py ../고군분투.swf && cp scene.json ../game/
python3 ../tools/extract_sounds.py ../고군분투.swf snd ../game/sounds.json
```
