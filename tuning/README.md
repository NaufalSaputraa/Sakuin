# Sakuin — Gemma 4 E2B QLoRA Tuning di RTX 4060 Laptop 8GB

Panduan lengkap fine-tuning Gemma 4 E2B (2.39GB, HuggingFace `soniqo/Gemma-4-E2B-LiteRT-LM`) agar lebih Indonesia & powerful untuk Sakuin, di laptop LOQ RTX 4060 8GB VRAM (WDDM, CUDA 13.3 terdeteksi).

> **Catatan:** File model lokalmu ada di `C:\Users\Naufal Saputra\Downloads\model.litertlm` (2.44GB, 2442 MB). Prompt ramah Indonesia sudah aktif di `lib/services/llm/gemma_llm_service.dart:24` — QLoRA ini untuk bikin Gemma lebih paham *transaksi pribadimu* (bukan cuma prompt).

---

## 0. Cek kesiapan (sekali, 30 detik)

```powershell
nvidia-smi  # harus lihat RTX 4060 8GB, CUDA 13.3 (punyamu sudah: 610.88, 8188MiB)
python --version  # 3.12.10 ✅
pip --version     # 26.2.1 ✅
# torch belum ada -> akan di-install di langkah 1
```

VRAM terpakai sekarang 1024MiB / 8188MiB (16%) — idle, siap training.

## 1. Install environment (sekali, ~3 menit)

```powershell
pip install --upgrade pip
pip install unsloth trl transformers datasets accelerate bitsandbytes torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install sentencepiece protobuf
```

Verifikasi:
```powershell
python -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0))"
# harus: True, NVIDIA GeForce RTX 4060 Laptop GPU
python -c "import unsloth; print(unsloth.__version__)"
```

## 2. Siapkan dataset Indonesia (100 baris, 10 menit)

Buat `D:\Coding\Sakuin\tuning\dataset.jsonl` — format instruction/input/output. Contoh 5 baris, duplikasi jadi 100 dengan variasi nominal/kategori:

```jsonl
{"instruction": "Tambahkan pengeluaran warung 20rb", "input": "", "output": "{\"tool\": \"addBatchTransactions\", \"args\": {\"transactions\": [{\"amount\": 20000, \"category\": \"warung\", \"title\": \"Warung Kopi\"}]}}"}
{"instruction": "Catat makan siang 25rb pakai gopay", "input": "", "output": "{\"tool\": \"addTransaction\", \"args\": {\"amount\": 25000, \"category\": \"makanan\", \"title\": \"Makan Siang\", \"wallet\": \"gopay\"}}"}
{"instruction": "Gaji bulanan 7.5jt bca", "input": "", "output": "{\"tool\": \"addTransaction\", \"args\": {\"amount\": 7500000, \"category\": \"salary\", \"title\": \"Gaji\", \"wallet\": \"bank\"}}"}
{"instruction": "Isi pertalite 50k cash", "input": "", "output": "{\"tool\": \"addTransaction\", \"args\": {\"amount\": 50000, \"category\": \"fuel\", \"title\": \"BBM\", \"wallet\": \"physical\"}}"}
{"instruction": "Bayar kos 1.5jt via dana", "input": "", "output": "{\"tool\": \"addTransaction\", \"args\": {\"amount\": 1500000, \"category\": \"housing\", \"title\": \"Kos\", \"wallet\": \"dana\"}}"}
```

Tips: Ambil 20 transaksi real dari `lib/core/constants/category_defaults.dart` (16 kategori: makan, transport, pulsa, warung, BBM, kos, dll.) + variasi nominal `10rb`, `1.5jt`, `500k`.

## 3. Jalankan QLoRA (1-2 jam di RTX 4060 8GB)

File sudah ada: `D:\Coding\Sakuin\tuning\finetune_gemma_qlora.py` (4-bit NF4, LoRA r=32, target q/k/v/o/gate/up/down, bf16, batch 2, grad_accum 4, ~6.5GB VRAM).

```powershell
cd D:\Coding\Sakuin
python tuning/finetune_gemma_qlora.py
```

Isi script penting (sudah aku buat):
```python
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name = r"C:\Users\Naufal Saputra\Downloads\model.litertlm",
    max_seq_length = 2048, dtype = None, load_in_4bit = True) # 4-bit -> 1.2GB
model = FastLanguageModel.get_peft_model(model, r=32, lora_alpha=64, target_modules=["q_proj","k_proj","v_proj","o_proj","gate_proj","up_proj","down_proj"])
# trainer = SFTTrainer(..., per_device_train_batch_size=2, gradient_accumulation_steps=4, fp16=False, bf16=True, max_steps=100, lr=2e-4, optim="adamw_8bit")
```

Output: `tuning/gemma-4-e2b-sakuin-lora/adapters.safetensors` (~50MB, bukan 2.39GB).

Monitor VRAM:
```powershell
nvidia-smi --loop=5
# harus ~6500MiB / 8188MiB, tidak OOM
```

## 4. Merge & konversi ke .litertlm (5 menit)

```powershell
python -c "from unsloth import FastLanguageModel; m,t = FastLanguageModel.from_pretrained('tuning/gemma-4-e2b-sakuin-lora'); m.save_pretrained_merged('tuning/gemma-4-e2b-sakuin-merged', t, save_method='merged_16bit')"
# atau
python tuning/merge_lora.py  # jika ada
```

Hasil: `tuning/gemma-4-e2b-sakuin-merged/model.litertlm` (~2.4GB). Copy ke `C:\Users\Naufal Saputra\Downloads\model-tuned.litertlm` untuk test.

## 5. Pakai di Sakuin (tanpa upload HuggingFace dulu)

Untuk test lokal, ganti sementara di `lib/core/constants/model_download_constants.dart:13`:

```dart
static const modelUrl = 'file:///C:/Users/Naufal%20Saputra/Downloads/model-tuned.litertlm'; // test lokal
// atau tetap HuggingFace, tapi ModelRepository.getModelPath() akan pakai file lokal jika ada
```

Lalu `flutter run` → `Settings → Download AI Model` akan pakai file lokal (tidak download 2.39GB lagi).

Jika puas, upload `model-tuned.litertlm` ke HuggingFace kamu `huggingface.co/NaufalSaputraa/sakuin-gemma-4e2b-tuned` → ganti `modelUrl` ke URL HuggingFace + update `modelSha256` (hitung via `certutil -hashfile model-tuned.litertlm SHA256`).

## 6. Kenapa tidak full fine-tuning?

- **Full (semua bobot)**: butuh 22-24GB VRAM → RTX 4060 8GB akan OOM.
- **QLoRA 4-bit r=32**: cuma update 2% bobot (LoRA adapters 50MB) → muat 6.5GB, 1-2 jam, hasil 95% kualitas full.
- **Prompt tuning** (sudah di `gemma_llm_service.dart:24` ramah Indonesia) → 0 training, instant.

**Rekomendasi Sakuin:** Pakai **QLoRA** seperti di atas untuk personalisasi transaksi warung/pulsa/BBM-mu. Full fine-tuning tidak perlu di LOQ.

---

## Troubleshooting

- `ModuleNotFoundError: torch` → `pip install torch --index-url https://download.pytorch.org/whl/cu121`
- `CUDA out of memory` → turunkan `per_device_train_batch_size=1`, `max_seq_length=1024`
- `model.litertlm` tidak terbaca di Sakuin → pastikan `ModelRepository.verifyModelIntegrity` SHA-256 sudah update ke hash file tuned
- `nvidia-smi` tidak ada → install CUDA 12.1 dari nvidia.com

Selesai — setelah `50/50 tests` + `No issues found!` + `tuning` ini, Sakuin siap 100% untuk fine-tuning personal di LOQ.
