# Gerador de QR Codes PIX - LacTech

Sistema completo para gerar QR codes PIX seguindo o padrão EMV do Banco Central, com suporte a diferentes tipos de chaves PIX e integração com cobranças bancárias.

## 🚀 Funcionalidades

- ✅ **QR Code PIX Simples**: Gera QR codes básicos com valor e descrição
- ✅ **QR Code da Cobrança**: Integra com cobranças do banco usando ID específico
- ✅ **QR Code Personalizado**: Suporta diferentes tipos de chave PIX (email, CPF, telefone, aleatória)
- ✅ **Validação EMV**: Verifica se o QR code gerado está no formato correto
- ✅ **Decodificação**: Decodifica QR codes PIX existentes
- ✅ **Interface Web**: Demonstração interativa com visualização do QR code

## 📁 Arquivos

- `pix_payment_system.js` - Sistema principal de pagamento PIX
- `pix_qr_generator.js` - Gerador de QR codes PIX
- `pix_qr_demo.html` - Página de demonstração interativa

## 🔧 Como Usar

### 1. QR Code Simples

```javascript
// Inicializar gerador
const qrGenerator = new PixQRGenerator();

// Gerar QR code simples
const qrData = qrGenerator.generateSimplePixQR(50.00, 'Pagamento LacTech');
console.log('QR Code:', qrData.qrCode);
```

### 2. QR Code da Cobrança do Banco

```javascript
// Dados da cobrança do banco
const chargeData = {
    amount: 100.00,
    chargeId: 'COBRANCA_12345',
    merchantName: 'LacTech Sistema Leiteiro',
    merchantCity: 'SAO PAULO'
};

// Gerar QR code baseado na cobrança
const qrData = qrGenerator.generateQRFromBankCharge(chargeData);
```

### 3. QR Code com Chave Personalizada

```javascript
// QR code com CPF
const qrData = qrGenerator.generateCustomPixQR(25.00, '12345678901', 'cpf');

// QR code com telefone
const qrData = qrGenerator.generateCustomPixQR(30.00, '11987654321', 'telefone');

// QR code com email
const qrData = qrGenerator.generateCustomPixQR(40.00, 'pagamento@empresa.com', 'email');
```

### 4. Validação e Decodificação

```javascript
// Validar QR code
const validation = qrGenerator.validateQRCode(qrData.qrCode);
if (validation.valid) {
    console.log('QR Code válido!');
} else {
    console.log('Erro:', validation.error);
}

// Decodificar QR code existente
const qrCode = '00020126580014BR.GOV.BCB.PIX0136ebabf96f-5162-4bd1-95c5-64ffa8e9bfed52040000530398654041.005802BR5924Francisco Lavosier Silva6009SAO PAULO62140510d7tboHbbcE6304802C';
const decoded = qrGenerator.decodeQRCode(qrCode);
console.log('QR Code decodificado:', decoded);
```

## 📋 Formato EMV PIX

O sistema gera QR codes seguindo o padrão EMV QR Code PIX do Banco Central:

```
000201                    # Payload Format Indicator (QR Code)
010212                    # Point of Initiation Method (Static)
26                        # Merchant Account Information
0014br.gov.bcb.pix       # GUI (PIX)
01XXchave                # PIX Key
52040000                  # Merchant Category Code
5303986                   # Transaction Currency (BRL)
54XXvalor                # Transaction Amount
5802BR                    # Country Code
59XXnome                 # Merchant Name
60XXcidade               # Merchant City
62                        # Additional Data Field Template
05XXtxid                 # Reference Label
6304XXXX                 # CRC16
```

## 🎯 Exemplos de Uso

### Exemplo 1: QR Code Simples
```javascript
const qrData = qrGenerator.generateSimplePixQR(75.50, 'Assinatura LacTech Pro');
// Resultado: QR code para pagamento de R$ 75,50
```

### Exemplo 2: QR Code da Cobrança
```javascript
const chargeData = {
    amount: 150.00,
    chargeId: 'COBRANCA_2024001',
    merchantName: 'LacTech Sistema Leiteiro',
    merchantCity: 'SAO PAULO'
};
const qrData = qrGenerator.generateQRFromBankCharge(chargeData);
// Resultado: QR code baseado na cobrança do banco
```

### Exemplo 3: QR Code com CPF
```javascript
const qrData = qrGenerator.generateCustomPixQR(30.00, '12345678901', 'cpf');
// Resultado: QR code usando CPF como chave PIX
```

## 🖥️ Interface Web

Para testar o sistema visualmente, abra o arquivo `pix_qr_demo.html` no navegador. A página inclui:

- ✅ Formulários para gerar diferentes tipos de QR code
- ✅ Visualização do QR code gerado
- ✅ Informações detalhadas do QR code
- ✅ Validação em tempo real
- ✅ Exemplos pré-configurados
- ✅ Documentação completa

## 🔧 Configuração

### 1. Incluir no HTML

```html
<!-- Incluir o gerador de QR codes -->
<script src="pix_qr_generator.js"></script>

<!-- Para visualização do QR code -->
<script src="https://cdn.jsdelivr.net/npm/qrcode@1.5.3/build/qrcode.min.js"></script>
```

### 2. Configurar Chave PIX

```javascript
// No arquivo pix_qr_generator.js, altere a chave PIX padrão:
this.pixKey = 'sua-chave-pix@email.com';
this.pixKeyType = 'email'; // email, cpf, telefone, aleatoria
```

### 3. Integrar com Sistema de Pagamento

```javascript
// No sistema de pagamento principal
const pixSystem = new PixPaymentSystem();
const qrData = pixSystem.generateQRFromBankCharge({
    amount: 100.00,
    chargeId: 'COBRANCA_12345',
    merchantName: 'Sua Empresa',
    merchantCity: 'Sua Cidade'
});
```

## 🧪 Testes

### Teste 1: QR Code Válido
```javascript
const qrData = qrGenerator.generateSimplePixQR(50.00);
const validation = qrGenerator.validateQRCode(qrData.qrCode);
console.log('Válido:', validation.valid); // true
```

### Teste 2: Decodificação
```javascript
const qrCode = '00020126580014BR.GOV.BCB.PIX0136ebabf96f-5162-4bd1-95c5-64ffa8e9bfed52040000530398654041.005802BR5924Francisco Lavosier Silva6009SAO PAULO62140510d7tboHbbcE6304802C';
const decoded = qrGenerator.decodeQRCode(qrCode);
console.log('Decodificado:', decoded);
```

## 📊 Estrutura de Dados

### QR Code Data
```javascript
{
    qrCode: '000201...',           // Código EMV completo
    txid: 'PIX_abc123...',         // ID da transação
    amount: 50.00,                 // Valor da transação
    pixKey: 'chave@email.com',     // Chave PIX
    expiresAt: '2024-01-01T...',  // Data de expiração
    merchantName: 'Empresa',       // Nome da empresa (opcional)
    merchantCity: 'Cidade'         // Cidade (opcional)
}
```

### Charge Data
```javascript
{
    amount: 100.00,                // Valor da cobrança
    chargeId: 'COBRANCA_12345',    // ID da cobrança do banco
    merchantName: 'Empresa',       // Nome da empresa
    merchantCity: 'Cidade'         // Cidade
}
```

## 🔒 Segurança

- ✅ Validação de formato EMV
- ✅ Verificação de CRC16
- ✅ Sanitização de dados de entrada
- ✅ Timeout de expiração configurável
- ✅ IDs únicos para cada transação

## 🚀 Próximos Passos

1. **Integração com Banco**: Conectar com APIs bancárias para cobranças reais
2. **Webhook de Pagamento**: Receber notificações de pagamento confirmado
3. **Histórico de Transações**: Armazenar QR codes gerados
4. **Relatórios**: Dashboard com estatísticas de pagamentos
5. **Multi-tenant**: Suporte a múltiplas empresas

## 📞 Suporte

Para dúvidas ou problemas:

- 📧 Email: suporte@lactech.com
- 📱 WhatsApp: (11) 99999-9999
- 🌐 Website: www.lactech.com

---

**Desenvolvido por LacTech Sistema Leiteiro** 🐄
